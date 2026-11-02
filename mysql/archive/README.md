# mysql/archive — research archive (`${DB_NAME_ARCHIVE}`, e.g. `mcb_check_archive`)

SPEC_14. Long-retention, immutable, point-in-time copy of each Closed business day.
Applied by `tools/apply-db.py` like every other `mysql/<db>/` folder (the database is
auto-created from the `USE` line; all files are re-apply-safe `CREATE TABLE IF NOT EXISTS`).

## Files

| File | Tables |
|---|---|
| `01_archive_day_file_letter_bundle.sql` | ARCHIVE_BUSINESS_DAY, _INBOUND_FILE_DETAILS, _CASH_LETTER_DETAILS, _BUNDLE_DETAILS |
| `02_archive_item_tables.sql` | ARCHIVE_ITEM_DETAILS, _ITEM_DETAILS_ENRICHED, _ITEM_DETAILS_REC, _ITEM_DETAILS_ADDENDA, _ITEM_IMAGE_REF |
| `03_archive_audit_ade_downstream.sql` | ARCHIVE_ITEM_AUDIT_TRAIL, _ADE_CORRECTION_LOG, _ADE_ADJUSTMENT_HISTORY, _POSTING_EOD_FILES, _IA_ARCHIVE_ITEM, _IA_ARCHIVE_FILE |
| `04_archive_dup_detect_advice.sql` | ARCHIVE_WORK_ITEM_CHECK_DETAILS, _WORK_ITEM_CHECK_DUPLICATE, _ITEM_ADVICE_REQUEST, _CUSTOMER_ADVICE |
| `05_archive_item_summary.sql` | ARCHIVE_ITEM_SUMMARY (denormalized, built by the sweep) |
| `06_archive_sweep_log.sql` | ARCHIVE_SWEEP_LOG (watermark, audit, legal hold; not partitioned) |

## Copy contract (identical-copy tables)

- Every `ARCHIVE_<X>` table has **the same column names as its source table `<X>`**,
  plus `ARCHIVE_BUS_DATE DATE NOT NULL` and `ARCHIVED_AT TIMESTAMP`.
- The sweep copies by **column-name intersection**: `INSERT INTO ARCHIVE_X (cols) SELECT cols
  FROM <source>.X WHERE <day scope>`, where `cols` = columns present in both tables,
  and `ARCHIVE_BUS_DATE` is set to the closed day's business date. `ARCHIVED_AT` defaults.
- Values are copied verbatim, so `AUTO_INCREMENT` is removed in the archive and
  `ON UPDATE CURRENT_TIMESTAMP` is stripped (rows are never updated after write).
- No foreign keys and no unique key that omits `ARCHIVE_BUS_DATE` (InnoDB requires the
  partition column in every PK/unique key and forbids FKs on partitioned tables).
  Source unique keys became plain indexes. PK = source PK columns + `ARCHIVE_BUS_DATE`.
- `ARCHIVE_ITEM_DETAILS_ENRICHED`: the source has no PK; PK is (`PAYMENT_ID`, `ARCHIVE_BUS_DATE`).
- `ARCHIVE_BUSINESS_DAY`: PK is (`ID`, `ARCHIVE_BUS_DATE`) (source PK is `ID` since
  `primary/07_business_day_category.sql`); `BDAY_ID`/`CATEGORY` are indexed columns.
- When a column is added to an operational source table, add it to the archive table too
  (the intersection copy silently skips columns the archive lacks).

## Partitioning

`PARTITION BY RANGE (TO_DAYS(ARCHIVE_BUS_DATE))`, one partition per month
(`p202601` ... `p202712`, `pYYYYMM` holds dates before the first of the next month;
`p202601` also catches anything earlier) plus `pMAX`. Add the next month before it is
needed (run per partitioned table, e.g. for 2028-01):

```sql
ALTER TABLE ARCHIVE_ITEM_DETAILS REORGANIZE PARTITION pMAX INTO (
  PARTITION p202801 VALUES LESS THAN (TO_DAYS('2028-02-01')),
  PARTITION pMAX VALUES LESS THAN MAXVALUE
);
```

Because new months are cut from `pMAX`, this is cheap while `pMAX` is empty. Do this for every
partitioned archive table (all except `ARCHIVE_SWEEP_LOG`). Prune old data with
`ALTER TABLE ... DROP PARTITION pYYYYMM` (gated on `ARCHIVE_SWEEP_LOG.LEGAL_HOLD`).
