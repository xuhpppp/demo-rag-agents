# Synthea データベース構造ドキュメント

Synthea（合成患者データジェネレーター）から出力されたCSVデータ用のMySQLデータベーススキーマです。

## ER図概要

```
organizations ──< providers ──< encounters >── patients
                                    │              │
                   payers ──────────┘              ├──< payer_transitions >── payers
                                                   │
              ┌────────────────────────────────────┤
              │         │         │         │      │
          conditions allergies medications  │   careplans
                                            │
              ┌─────────────────────────────┤
              │         │         │         │
          procedures observations immunizations
              │         │
          devices  imaging_studies  supplies
              │
          claims ──< claims_transactions
```

---

## テーブル一覧

| # | テーブル名 | 説明 | 主キー型 |
|---|-----------|------|---------|
| 1 | `organizations` | 医療機関マスタ | UUID |
| 2 | `payers` | 保険者マスタ | UUID |
| 3 | `patients` | 患者マスタ | UUID |
| 4 | `providers` | 医療提供者マスタ | UUID |
| 5 | `encounters` | 受診記録 | UUID |
| 6 | `payer_transitions` | 保険加入履歴 | AUTO_INCREMENT |
| 7 | `conditions` | 疾患・状態記録 | AUTO_INCREMENT |
| 8 | `allergies` | アレルギー記録 | AUTO_INCREMENT |
| 9 | `medications` | 処方記録 | AUTO_INCREMENT |
| 10 | `procedures` | 処置記録 | AUTO_INCREMENT |
| 11 | `observations` | 観察・検査結果 | AUTO_INCREMENT |
| 12 | `immunizations` | 予防接種記録 | AUTO_INCREMENT |
| 13 | `careplans` | ケアプラン | UUID |
| 14 | `devices` | 医療機器記録 | AUTO_INCREMENT |
| 15 | `imaging_studies` | 画像検査記録 | UUID |
| 16 | `supplies` | 医療物品記録 | AUTO_INCREMENT |
| 17 | `claims` | 保険請求 | UUID |
| 18 | `claims_transactions` | 請求明細取引 | UUID |

---

## テーブル詳細

### 1. `organizations` — 医療機関マスタ

病院・クリニック・診療所などの基本情報を管理するマスタテーブルです。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 医療機関の一意識別子（UUID） |
| `name` | VARCHAR(255) | 医療機関名 |
| `address` | VARCHAR(255) | 所在地（番地） |
| `city` | VARCHAR(100) | 市区町村 |
| `state` | VARCHAR(10) | 州コード |
| `zip` | VARCHAR(15) | 郵便番号 |
| `lat` | DECIMAL(10,7) | 緯度 |
| `lon` | DECIMAL(10,7) | 経度 |
| `phone` | VARCHAR(20) | 電話番号 |
| `revenue` | DECIMAL(15,2) | 収益額（USD） |
| `utilization` | INT | 利用件数 |

---

### 2. `payers` — 保険者マスタ

公的保険（Medicare, Medicaid等）や民間保険会社の情報と、保険適用の統計を管理します。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 保険者の一意識別子（UUID） |
| `name` | VARCHAR(255) | 保険者名 |
| `ownership` | VARCHAR(50) | 運営形態（GOVERNMENT / PRIVATE 等） |
| `address` | VARCHAR(255) | 所在地（番地） |
| `city` | VARCHAR(100) | 市区町村 |
| `state_headquartered` | VARCHAR(50) | 本部所在州 |
| `zip` | VARCHAR(15) | 郵便番号 |
| `phone` | VARCHAR(20) | 電話番号 |
| `amount_covered` | DECIMAL(15,2) | 保険適用合計額（USD） |
| `amount_uncovered` | DECIMAL(15,2) | 保険適用外合計額（USD） |
| `revenue` | DECIMAL(15,2) | 収益額（USD） |
| `covered_encounters` | INT | 保険適用の受診件数 |
| `uncovered_encounters` | INT | 保険適用外の受診件数 |
| `covered_medications` | INT | 保険適用の処方件数 |
| `uncovered_medications` | INT | 保険適用外の処方件数 |
| `covered_procedures` | INT | 保険適用の処置件数 |
| `uncovered_procedures` | INT | 保険適用外の処置件数 |
| `covered_immunizations` | INT | 保険適用の予防接種件数 |
| `uncovered_immunizations` | INT | 保険適用外の予防接種件数 |
| `unique_customers` | INT | 被保険者数（ユニーク） |
| `qols_avg` | DECIMAL(10,8) | 生活の質（QOL）平均スコア |
| `member_months` | INT | 延べ加入月数 |

---

### 3. `patients` — 患者マスタ

患者の人口統計情報・住所・保険関連の基本情報です。Syntheaの中核テーブルであり、ほぼ全テーブルがこのテーブルを参照します。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 患者の一意識別子（UUID） |
| `birthdate` | DATE | 生年月日 |
| `deathdate` | DATE | 死亡日（生存中はNULL） |
| `ssn` | VARCHAR(11) | 社会保障番号 |
| `drivers` | VARCHAR(20) | 運転免許証番号 |
| `passport` | VARCHAR(20) | パスポート番号 |
| `prefix` | VARCHAR(10) | 敬称（Mr. / Mrs. / Ms. 等） |
| `first_name` | VARCHAR(50) | 名 |
| `middle_name` | VARCHAR(50) | ミドルネーム |
| `last_name` | VARCHAR(50) | 姓 |
| `suffix` | VARCHAR(10) | 接尾辞（Jr. / Sr. 等） |
| `maiden` | VARCHAR(50) | 旧姓 |
| `marital` | CHAR(1) | 婚姻状況（M=既婚, S=未婚） |
| `race` | VARCHAR(20) | 人種 |
| `ethnicity` | VARCHAR(20) | 民族 |
| `gender` | CHAR(1) | 性別（M=男性, F=女性） |
| `birthplace` | VARCHAR(100) | 出生地 |
| `address` | VARCHAR(100) | 住所（番地） |
| `city` | VARCHAR(50) | 市区町村 |
| `state` | VARCHAR(50) | 州 |
| `county` | VARCHAR(50) | 郡 |
| `fips` | VARCHAR(10) | FIPS地域コード |
| `zip` | VARCHAR(10) | 郵便番号 |
| `lat` | DECIMAL(18,14) | 緯度 |
| `lon` | DECIMAL(18,14) | 経度 |
| `healthcare_expenses` | DECIMAL(12,2) | 医療費総額（USD） |
| `healthcare_coverage` | DECIMAL(12,2) | 保険適用総額（USD） |
| `income` | INT | 年収（USD） |

---

### 4. `providers` — 医療提供者マスタ

医師・看護師などの医療提供者の情報です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 医療提供者の一意識別子（UUID） |
| `organization_id` | VARCHAR(36) FK | 所属医療機関ID |
| `name` | VARCHAR(255) | 氏名 |
| `gender` | CHAR(1) | 性別（M=男性, F=女性） |
| `speciality` | VARCHAR(255) | 専門分野 |
| `address` | VARCHAR(255) | 所在地（番地） |
| `city` | VARCHAR(100) | 市区町村 |
| `state` | VARCHAR(10) | 州コード |
| `zip` | VARCHAR(15) | 郵便番号 |
| `lat` | DECIMAL(10,7) | 緯度 |
| `lon` | DECIMAL(10,7) | 経度 |
| `encounters` | INT | 受診件数 |
| `procedures` | INT | 処置件数 |

**FK**: `organization_id` → `organizations.id`

---

### 5. `encounters` — 受診記録

外来・入院・救急・健康診断などすべての受診イベントを記録します。臨床データテーブルの多くがこのテーブルを経由して患者に紐づきます。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 受診の一意識別子（UUID） |
| `start` | DATETIME | 受診開始日時 |
| `stop` | DATETIME | 受診終了日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `organization_id` | VARCHAR(36) FK | 医療機関ID |
| `provider_id` | VARCHAR(36) FK | 医療提供者ID |
| `payer_id` | VARCHAR(36) FK | 保険者ID |
| `encounterclass` | VARCHAR(50) | 受診区分（wellness / ambulatory / emergency / inpatient / urgentcare） |
| `code` | VARCHAR(20) | SNOMED-CTコード |
| `description` | VARCHAR(500) | 受診内容の説明 |
| `base_encounter_cost` | DECIMAL(10,2) | 基本受診費用（USD） |
| `total_claim_cost` | DECIMAL(10,2) | 請求総額（USD） |
| `payer_coverage` | DECIMAL(10,2) | 保険者負担額（USD） |
| `reasoncode` | VARCHAR(20) | 受診理由コード（SNOMED-CT） |
| `reasondescription` | VARCHAR(500) | 受診理由の説明 |

**FK**: `patient_id` → `patients.id`, `organization_id` → `organizations.id`, `provider_id` → `providers.id`, `payer_id` → `payers.id`

---

### 6. `payer_transitions` — 保険加入履歴

患者の保険の切替・移行の記録です。患者が異なる保険者へ移行した履歴を時系列で追跡できます。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `member_id` | VARCHAR(36) | 被保険者番号 |
| `start_date` | DATETIME | 加入開始日時 |
| `end_date` | DATETIME | 加入終了日時 |
| `payer_id` | VARCHAR(36) FK | 主保険者ID |
| `secondary_payer` | VARCHAR(36) | 副保険者ID |
| `plan_ownership` | VARCHAR(50) | 加入区分（Self / Spouse / Child 等） |
| `owner_name` | VARCHAR(255) | 加入者名 |

**FK**: `patient_id` → `patients.id`, `payer_id` → `payers.id`

---

### 7. `conditions` — 疾患・状態記録

患者に診断された疾患・健康状態を記録します。`stop`がNULLの場合、現在も継続中の疾患です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `start` | DATE | 発症日 |
| `stop` | DATE | 治癒日（継続中はNULL） |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `system` | VARCHAR(255) | コード体系URI（例: http://snomed.info/sct） |
| `code` | VARCHAR(20) | 疾患コード（SNOMED-CT） |
| `description` | VARCHAR(500) | 疾患名の説明 |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 8. `allergies` — アレルギー記録

患者のアレルギー情報とアレルギー反応の詳細です。最大2つの反応を記録可能です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `start` | DATE | アレルギー記録開始日 |
| `stop` | DATE | アレルギー解消日（継続中はNULL） |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | SNOMED-CTコード |
| `system` | VARCHAR(255) | コード体系（SNOMED-CT等） |
| `description` | VARCHAR(500) | アレルゲンの説明 |
| `type` | VARCHAR(50) | アレルギー種別（allergy / intolerance） |
| `category` | VARCHAR(50) | カテゴリ（food / environment / medication） |
| `reaction1` | VARCHAR(20) | 反応1 コード |
| `description1` | VARCHAR(500) | 反応1 の説明 |
| `severity1` | VARCHAR(20) | 反応1 の重症度（MILD / MODERATE / SEVERE） |
| `reaction2` | VARCHAR(20) | 反応2 コード |
| `description2` | VARCHAR(500) | 反応2 の説明 |
| `severity2` | VARCHAR(20) | 反応2 の重症度（MILD / MODERATE / SEVERE） |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 9. `medications` — 処方記録

薬剤の処方・調剤情報です。費用と保険適用の内訳も含みます。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `start` | DATETIME | 処方開始日時 |
| `stop` | DATETIME | 処方終了日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `payer_id` | VARCHAR(36) FK | 保険者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | RxNormコード |
| `description` | VARCHAR(500) | 薬品名・用量の説明 |
| `base_cost` | DECIMAL(10,2) | 基本費用（USD） |
| `payer_coverage` | DECIMAL(10,2) | 保険者負担額（USD） |
| `dispenses` | INT | 調剤回数 |
| `totalcost` | DECIMAL(12,2) | 合計費用（USD） |
| `reasoncode` | VARCHAR(20) | 処方理由コード |
| `reasondescription` | VARCHAR(500) | 処方理由の説明 |

**FK**: `patient_id` → `patients.id`, `payer_id` → `payers.id`, `encounter_id` → `encounters.id`

---

### 10. `procedures` — 処置記録

手術・検査・治療等の医療処置を記録します。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `start` | DATETIME | 処置開始日時 |
| `stop` | DATETIME | 処置終了日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `system` | VARCHAR(255) | コード体系URI |
| `code` | VARCHAR(20) | 処置コード（SNOMED-CT） |
| `description` | VARCHAR(500) | 処置内容の説明 |
| `base_cost` | DECIMAL(10,2) | 基本費用（USD） |
| `reasoncode` | VARCHAR(20) | 処置理由コード |
| `reasondescription` | VARCHAR(500) | 処置理由の説明 |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 11. `observations` — 観察・検査結果

バイタルサイン（身長・体重・血圧等）、検査値、社会歴（喫煙状況等）を記録します。値は数値型とテキスト型の両方が混在するため、`value_text`と`value_numeric`の2カラム構成です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `date` | DATETIME | 観察日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `category` | VARCHAR(50) | カテゴリ（vital-signs / laboratory / social-history 等） |
| `code` | VARCHAR(20) | LOINCコード |
| `description` | VARCHAR(500) | 観察項目の説明 |
| `value_text` | VARCHAR(500) | 観察値（テキスト — 数値・文字列両方を格納） |
| `value_numeric` | DECIMAL(12,4) | 観察値（数値型にパース可能な場合） |
| `units` | VARCHAR(50) | 単位（cm / kg / mmHg 等） |
| `type` | VARCHAR(20) | 値の型（numeric / text） |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

> **設計ポイント**: CSVの`VALUE`列は `53.9`（数値）や `Never smoked tobacco (finding)`（テキスト）が混在しています。データロード時に `type = 'numeric'` の行は `value_numeric` にもパースして格納することで、数値クエリ（範囲検索・集計）が効率的になります。

---

### 12. `immunizations` — 予防接種記録

ワクチン接種の履歴です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `date` | DATETIME | 接種日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | CVXワクチンコード |
| `description` | VARCHAR(500) | ワクチン名の説明 |
| `base_cost` | DECIMAL(10,2) | 基本費用（USD） |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 13. `careplans` — ケアプラン

患者の治療計画・管理計画です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | ケアプランの一意識別子（UUID） |
| `start` | DATE | ケアプラン開始日 |
| `stop` | DATE | ケアプラン終了日（継続中はNULL） |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | SNOMED-CTコード |
| `description` | VARCHAR(500) | ケアプラン内容の説明 |
| `reasoncode` | VARCHAR(20) | ケアプラン理由コード |
| `reasondescription` | VARCHAR(500) | ケアプラン理由の説明 |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 14. `devices` — 医療機器記録

患者に使用された医療機器・器具の情報です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `start` | DATETIME | 使用開始日時 |
| `stop` | DATETIME | 使用終了日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | SNOMED-CTコード |
| `description` | VARCHAR(500) | 医療機器名の説明 |
| `udi` | VARCHAR(255) | UDI（固有機器識別子） |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 15. `imaging_studies` — 画像検査記録

X線・CT・MRI等のDICOM画像検査情報です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 画像検査の一意識別子（UUID） |
| `date` | DATETIME | 検査日時 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `series_uid` | VARCHAR(255) | DICOMシリーズUID |
| `bodysite_code` | VARCHAR(20) | 検査部位コード |
| `bodysite_description` | VARCHAR(255) | 検査部位の説明 |
| `modality_code` | VARCHAR(10) | モダリティコード（DX / CT / MR 等） |
| `modality_description` | VARCHAR(100) | モダリティの説明 |
| `instance_uid` | VARCHAR(255) | DICOMインスタンスUID |
| `sop_code` | VARCHAR(255) | SOP ClassのUID |
| `sop_description` | VARCHAR(255) | SOP Classの説明 |
| `procedure_code` | VARCHAR(20) | 検査処置コード |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 16. `supplies` — 医療物品記録

受診時に使用された消耗品・物品の記録です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | INT PK AUTO_INCREMENT | 自動採番ID |
| `date` | DATE | 供給日 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `encounter_id` | VARCHAR(36) FK | 受診ID |
| `code` | VARCHAR(20) | SNOMED-CTコード |
| `description` | VARCHAR(500) | 物品名の説明 |
| `quantity` | INT | 数量 |

**FK**: `patient_id` → `patients.id`, `encounter_id` → `encounters.id`

---

### 17. `claims` — 保険請求（レセプト）

診療報酬請求の情報です。最大8つの診断コードを保持し、主保険・副保険・患者自己負担の3系統のステータスを管理します。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 請求の一意識別子（UUID） |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `provider_id` | VARCHAR(36) FK | 医療提供者ID |
| `primary_patient_insurance_id` | VARCHAR(36) | 主保険の被保険者ID |
| `secondary_patient_insurance_id` | VARCHAR(36) | 副保険の被保険者ID |
| `department_id` | VARCHAR(10) | 診療科ID |
| `patient_department_id` | VARCHAR(10) | 患者診療科ID |
| `diagnosis1` ~ `diagnosis8` | VARCHAR(20) | 診断コード1〜8（SNOMED-CT） |
| `referring_provider_id` | VARCHAR(36) | 紹介元医療提供者ID |
| `appointment_id` | VARCHAR(36) | 予約ID（受診ID） |
| `current_illness_date` | DATETIME | 現病歴の開始日時 |
| `service_date` | DATETIME | 診療日時 |
| `supervising_provider_id` | VARCHAR(36) | 指導医ID |
| `status1` / `status2` / `statusp` | VARCHAR(20) | 主保険 / 副保険 / 患者自己負担のステータス |
| `outstanding1` / `outstanding2` / `outstandingp` | DECIMAL(10,2) | 主保険 / 副保険 / 患者自己負担の未払額（USD） |
| `lastbilleddate1` / `lastbilleddate2` / `lastbilleddatep` | DATETIME | 各系統の最終請求日時 |
| `healthcareclaimtypeid1` / `healthcareclaimtypeid2` | INT | 主保険 / 副保険の請求種別ID |

**FK**: `patient_id` → `patients.id`, `provider_id` → `providers.id`

---

### 18. `claims_transactions` — 請求明細取引

請求（`claims`）に対する費用・支払・調整・転送等の明細レベルの取引です。

| カラム | 型 | 説明 |
|--------|-----|------|
| `id` | VARCHAR(36) PK | 取引の一意識別子（UUID） |
| `claim_id` | VARCHAR(36) FK | 請求ID |
| `charge_id` | INT | 費目連番 |
| `patient_id` | VARCHAR(36) FK | 患者ID |
| `type` | VARCHAR(20) | 取引種別（CHARGE / PAYMENT / TRANSFERIN / TRANSFEROUT） |
| `amount` | DECIMAL(10,2) | 金額（USD） |
| `method` | VARCHAR(20) | 支払方法（ECHECK 等） |
| `from_date` | DATETIME | 対象期間開始日時 |
| `to_date` | DATETIME | 対象期間終了日時 |
| `place_of_service` | VARCHAR(36) | 診療場所ID（医療機関ID） |
| `procedure_code` | VARCHAR(20) | 処置コード |
| `modifier1` / `modifier2` | VARCHAR(10) | 修飾子1・2 |
| `diagnosisref1` ~ `diagnosisref4` | INT | 診断参照1〜4 |
| `units` | INT | 数量 |
| `department_id` | VARCHAR(10) | 診療科ID |
| `notes` | TEXT | 備考 |
| `unit_amount` | DECIMAL(10,2) | 単価（USD） |
| `transfer_out_id` | VARCHAR(36) | 転送先取引ID |
| `transfer_type` | VARCHAR(10) | 転送区分 |
| `payments` | DECIMAL(10,2) | 支払額（USD） |
| `adjustments` | DECIMAL(10,2) | 調整額（USD） |
| `transfers` | DECIMAL(10,2) | 転送額（USD） |
| `outstanding` | DECIMAL(10,2) | 未払額（USD） |
| `appointment_id` | VARCHAR(36) | 予約ID（受診ID） |
| `line_note` | TEXT | 明細備考 |
| `patient_insurance_id` | VARCHAR(36) | 被保険者ID |
| `fee_schedule_id` | VARCHAR(10) | 診療報酬表ID |
| `provider_id` | VARCHAR(36) | 医療提供者ID |
| `supervising_provider_id` | VARCHAR(36) | 指導医ID |

**FK**: `claim_id` → `claims.id`, `patient_id` → `patients.id`

---

## コード体系について

| コード体系 | 使用テーブル | 説明 |
|-----------|-------------|------|
| **SNOMED-CT** | conditions, procedures, encounters, allergies, devices, supplies, careplans | 臨床用語の国際標準体系 |
| **LOINC** | observations | 検査・観察項目の標準コード |
| **RxNorm** | medications | 医薬品の標準コード（米国） |
| **CVX** | immunizations | ワクチンの標準コード（CDC） |
| **DICOM UID** | imaging_studies | 医用画像の固有識別子 |

## データロード順序

外部キー制約を満たすため、以下の順序でデータをロードしてください:

1. `organizations`
2. `payers`
3. `patients`
4. `providers`
5. `encounters`
6. `payer_transitions`
7. `conditions`, `allergies`, `medications`, `procedures`, `observations`, `immunizations`, `careplans`, `devices`, `imaging_studies`, `supplies` （並列可）
8. `claims`
9. `claims_transactions`
