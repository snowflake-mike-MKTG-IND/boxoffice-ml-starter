#!/usr/bin/env python3
"""Reference implementation of the trailer-signal opening-weekend model.

A distributional regressor with strict walk-forward temporal validation:
  * two base learners (CatBoost + ElasticNet) blended via a residual mixture,
  * a full predictive distribution per film -> HDR50 band, Bayes point, P78 upside,
  * a calibrated demand-forward flag (P(opening >= $50M)) that lifts confident large films,
  * pedigree already gated behind demand inside the OW_FEATURES view,
  * judged on an asymmetric flop-safety loss.

Source-neutral: reads whatever you loaded into {DB}.RESEARCH.OW_FEATURES. See
docs/07_model_architecture.md for the narrative. This is a starting point — tune it.

Run:  python model/train_ow_model.py --connection my_sandbox --database MY_SANDBOX_DB
Deps: pip install -r model/requirements.txt
"""
import argparse, json, warnings
import numpy as np, pandas as pd
warnings.filterwarnings("ignore")
from sklearn.linear_model import ElasticNetCV
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.calibration import CalibratedClassifierCV
from catboost import CatBoostRegressor
import snowflake.connector

# Columns that are keys/targets, not features
NON_FEATURES = {"MOVIE_ID", "MOVIE_TITLE", "RELEASE_DATE", "DAYS_OUT",
                "OPENING_WEEKEND", "LOG_OPENING_WEEKEND", "THEATER_COUNT"}
LARGE = 50e6          # LARGE+ tier threshold ($50M)
HALFLIFE_MONTHS = 24  # time-decay half-life for sample weights


def load_features(conn_name, database):
    con = snowflake.connector.connect(connection_name=conn_name)
    df = pd.read_sql(f"SELECT * FROM {database}.RESEARCH.OW_FEATURES", con).fillna(0)
    con.close()
    df.columns = [c.upper() for c in df.columns]
    df["RELEASE_DATE"] = pd.to_datetime(df["RELEASE_DATE"])
    return df


def cbr():
    return CatBoostRegressor(loss_function="RMSE", verbose=0, random_seed=42,
                             iterations=500, depth=5, learning_rate=0.03,
                             l2_leaf_reg=10, thread_count=-1)


def walk_forward_splits(df, n_blocks=8):
    """Sort films by release date; first 50% = base train; predict each of the next
    n_blocks using only earlier films. Returns list of (train_idx, test_idx) over rows."""
    first_date = df.groupby("MOVIE_ID")["RELEASE_DATE"].min().sort_values()
    films = first_date.index.values
    base = int(0.5 * len(films))
    rows = {f: np.where(df["MOVIE_ID"].values == f)[0] for f in films}
    blocks = np.array_split(films[base:], n_blocks)
    splits = []
    for i, blk in enumerate(blocks):
        train_films = np.concatenate([films[:base]] + [blocks[j] for j in range(i)]) if i else films[:base]
        tr = np.concatenate([rows[f] for f in train_films])
        te = np.concatenate([rows[f] for f in blk])
        splits.append((tr, te))
    return splits


def decay_weights(dates, cutoff):
    age_months = (cutoff - dates).dt.days.values / 30.44
    return 0.5 ** (age_months / HALFLIFE_MONTHS)


def hdr_triple(cb_point, lin_point, cb_res, lin_res):
    """Residual-mixture distribution -> (lo, hi, hdr50_mean, bayes q1/3, q0.55, p78)."""
    samples = np.exp(np.concatenate([cb_point + cb_res, lin_point + lin_res]))
    s = np.sort(samples); n = len(s); k = int(np.floor(0.5 * n))
    j = int(np.argmin(s[k:] - s[:n - k]))          # narrowest 50% window = HDR50
    lo, hi = s[j], s[j + k]
    hdr_mean = s[(s >= lo) & (s <= hi)].mean()
    return lo, hi, hdr_mean, np.quantile(samples, 1/3), np.quantile(samples, 0.55), np.quantile(samples, 0.78)


def aloss(pred, actual, r=2.0):
    lr = np.log(pred / actual)
    return float(np.mean(r * np.maximum(lr, 0) + np.maximum(-lr, 0)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--connection", required=True, help="named Snowflake connection")
    ap.add_argument("--database", required=True, help="sandbox database holding RESEARCH.OW_FEATURES")
    ap.add_argument("--out", default="model/oof_predictions.json")
    args = ap.parse_args()

    df = load_features(args.connection, args.database)
    feats = [c for c in df.columns if c not in NON_FEATURES and pd.api.types.is_numeric_dtype(df[c])]
    X = df[feats].values.astype(float)
    yln = df["LOG_OPENING_WEEKEND"].values
    ow = df["OPENING_WEEKEND"].values
    dates = df["RELEASE_DATE"]
    tier_large = (ow >= LARGE).astype(int)
    n = len(df)

    cb = np.full(n, np.nan); lin = np.full(n, np.nan); p_large = np.full(n, np.nan)
    for tr, te in walk_forward_splits(df):
        w = decay_weights(dates.iloc[tr], dates.iloc[tr].max())
        m = cbr(); m.fit(X[tr], yln[tr], sample_weight=w); cb[te] = m.predict(X[te])
        sc = StandardScaler().fit(X[tr])
        en = ElasticNetCV(l1_ratio=[.1, .5, .9], cv=5, max_iter=8000, random_state=42)
        en.fit(sc.transform(X[tr]), yln[tr], sample_weight=w); lin[te] = en.predict(sc.transform(X[te]))
        # demand-forward flag: P(opening >= $50M), calibrated
        if len(np.unique(tier_large[tr])) > 1:
            clf = CalibratedClassifierCV(
                RandomForestClassifier(n_estimators=400, min_samples_leaf=2, random_state=42, n_jobs=-1),
                method="isotonic", cv=3)
            clf.fit(X[tr], tier_large[tr])
            p_large[te] = clf.predict_proba(X[te])[:, list(clf.classes_).index(1)]
        else:
            p_large[te] = 0.0

    cov = ~np.isnan(cb)
    cb_res = (yln - cb)[cov]; lin_res = (yln - lin)[cov]     # pooled OOF residuals

    # one row per film at its latest available horizon
    last = df[cov].sort_values("DAYS_OUT").groupby("MOVIE_ID").tail(1)
    recs = []
    for i in last.index:
        lo, hi, hdr_mean, bayes, q55, p78 = hdr_triple(cb[i], lin[i], cb_res, lin_res)
        pl = float(p_large[i])
        point = max(hdr_mean, q55) if pl >= 0.4 else hdr_mean   # Track B lift for confident large films
        recs.append({"movie_title": df.at[i, "MOVIE_TITLE"], "actual_ow_m": round(ow[i]/1e6, 2),
                     "predicted_ow_m": round(point/1e6, 2), "bayes_ow_m": round(bayes/1e6, 2),
                     "hdr_lo_m": round(lo/1e6, 2), "hdr_hi_m": round(hi/1e6, 2),
                     "upside_p78_m": round(p78/1e6, 2), "p_large": round(pl, 3)})

    a = np.array([r["actual_ow_m"] for r in recs]) * 1e6
    p = np.array([r["predicted_ow_m"] for r in recs]) * 1e6
    ape = np.abs(p - a) / a
    inband = np.mean([(a[k] >= recs[k]["hdr_lo_m"]*1e6) & (a[k] <= recs[k]["hdr_hi_m"]*1e6) for k in range(len(recs))])
    big = a >= 60e6
    print(f"n_films            {len(recs)}")
    print(f"MAPE               {ape.mean()*100:5.1f}%")
    print(f"median APE         {np.median(ape)*100:5.1f}%")
    print(f"aLoss (flop-safe)  {aloss(p, a):.3f}")
    print(f"HDR50 coverage     {inband*100:5.1f}%   (target ~50%)")
    if big.sum():
        print(f">=$60M signed-log {np.mean(np.log(p[big]/a[big])):+.3f}   (neg = under-predict)")
    json.dump(recs, open(args.out, "w"), indent=1)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
