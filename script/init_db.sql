-- ============================================================
-- Synthea Patient Data - Database Schema for MySQL 8.0
-- Generated from Synthea CSV output
-- ============================================================

CREATE DATABASE IF NOT EXISTS `synthea_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `synthea_db`;

-- ============================================================
-- 1. Core Reference Tables (no FK dependencies)
-- ============================================================

CREATE TABLE `organizations` (
  `id`              VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '医療機関の一意識別子（UUID）',
  `name`            VARCHAR(255)   NOT NULL               COMMENT '医療機関名',
  `address`         VARCHAR(255)   DEFAULT NULL            COMMENT '所在地（番地）',
  `city`            VARCHAR(100)   DEFAULT NULL            COMMENT '市区町村',
  `state`           VARCHAR(10)    DEFAULT NULL            COMMENT '州コード',
  `zip`             VARCHAR(15)    DEFAULT NULL            COMMENT '郵便番号',
  `lat`             DECIMAL(18,14) DEFAULT NULL            COMMENT '緯度',
  `lon`             DECIMAL(18,14) DEFAULT NULL            COMMENT '経度',
  `phone`           VARCHAR(30)    DEFAULT NULL            COMMENT '電話番号',
  `revenue`         DECIMAL(15,2)  DEFAULT 0.00            COMMENT '収益額（USD）',
  `utilization`     INT            DEFAULT 0               COMMENT '利用件数'
) COMMENT = '医療機関マスタ — 病院・クリニック等の基本情報';


CREATE TABLE `payers` (
  `id`                        VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '保険者の一意識別子（UUID）',
  `name`                      VARCHAR(255)   NOT NULL               COMMENT '保険者名',
  `ownership`                 VARCHAR(50)    DEFAULT NULL            COMMENT '運営形態（GOVERNMENT / PRIVATE 等）',
  `address`                   VARCHAR(255)   DEFAULT NULL            COMMENT '所在地（番地）',
  `city`                      VARCHAR(100)   DEFAULT NULL            COMMENT '市区町村',
  `state_headquartered`       VARCHAR(50)    DEFAULT NULL            COMMENT '本部所在州',
  `zip`                       VARCHAR(15)    DEFAULT NULL            COMMENT '郵便番号',
  `phone`                     VARCHAR(30)    DEFAULT NULL            COMMENT '電話番号',
  `amount_covered`            DECIMAL(18,2)  DEFAULT 0.00            COMMENT '保険適用合計額（USD）',
  `amount_uncovered`          DECIMAL(18,2)  DEFAULT 0.00            COMMENT '保険適用外合計額（USD）',
  `revenue`                   DECIMAL(18,2)  DEFAULT 0.00            COMMENT '収益額（USD）',
  `covered_encounters`        INT            DEFAULT 0               COMMENT '保険適用の受診件数',
  `uncovered_encounters`      INT            DEFAULT 0               COMMENT '保険適用外の受診件数',
  `covered_medications`       INT            DEFAULT 0               COMMENT '保険適用の処方件数',
  `uncovered_medications`     INT            DEFAULT 0               COMMENT '保険適用外の処方件数',
  `covered_procedures`        INT            DEFAULT 0               COMMENT '保険適用の処置件数',
  `uncovered_procedures`      INT            DEFAULT 0               COMMENT '保険適用外の処置件数',
  `covered_immunizations`     INT            DEFAULT 0               COMMENT '保険適用の予防接種件数',
  `uncovered_immunizations`   INT            DEFAULT 0               COMMENT '保険適用外の予防接種件数',
  `unique_customers`          INT            DEFAULT 0               COMMENT '被保険者数（ユニーク）',
  `qols_avg`                  DECIMAL(10,8)  DEFAULT NULL            COMMENT '生活の質（QOL）平均スコア',
  `member_months`             INT            DEFAULT 0               COMMENT '延べ加入月数'
) COMMENT = '保険者マスタ — 公的・民間保険者の情報と集計統計';


CREATE TABLE `patients` (
  `id`                    VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '患者の一意識別子（UUID）',
  `birthdate`             DATE           NOT NULL               COMMENT '生年月日',
  `deathdate`             DATE           DEFAULT NULL            COMMENT '死亡日（生存中はNULL）',
  `ssn`                   VARCHAR(20)    DEFAULT NULL            COMMENT 'マイナンバー（個人番号12桁）',
  `drivers`               VARCHAR(20)    DEFAULT NULL            COMMENT '運転免許証番号',
  `passport`              VARCHAR(20)    DEFAULT NULL            COMMENT 'パスポート番号',
  `prefix`                VARCHAR(10)    DEFAULT NULL            COMMENT '敬称（Mr. / Mrs. / Ms. 等）',
  `first_name`            VARCHAR(50)    DEFAULT NULL            COMMENT '名',
  `middle_name`           VARCHAR(50)    DEFAULT NULL            COMMENT 'ミドルネーム',
  `last_name`             VARCHAR(50)    DEFAULT NULL            COMMENT '姓',
  `suffix`                VARCHAR(10)    DEFAULT NULL            COMMENT '接尾辞（Jr. / Sr. 等）',
  `maiden`                VARCHAR(50)    DEFAULT NULL            COMMENT '旧姓',
  `marital`               CHAR(1)        DEFAULT NULL            COMMENT '婚姻状況（M=既婚, S=未婚）',
  `race`                  VARCHAR(20)    DEFAULT NULL            COMMENT '人種',
  `ethnicity`             VARCHAR(20)    DEFAULT NULL            COMMENT '民族',
  `gender`                CHAR(1)        DEFAULT NULL            COMMENT '性別（M=男性, F=女性）',
  `birthplace`            VARCHAR(100)   DEFAULT NULL            COMMENT '出生地',
  `address`               VARCHAR(100)   DEFAULT NULL            COMMENT '住所（番地）',
  `city`                  VARCHAR(50)    DEFAULT NULL            COMMENT '市区町村',
  `state`                 VARCHAR(50)    DEFAULT NULL            COMMENT '州',
  `county`                VARCHAR(50)    DEFAULT NULL            COMMENT '郡',
  `fips`                  VARCHAR(10)    DEFAULT NULL            COMMENT 'FIPS地域コード',
  `zip`                   VARCHAR(10)    DEFAULT NULL            COMMENT '郵便番号',
  `lat`                   DECIMAL(18,14) DEFAULT NULL            COMMENT '緯度',
  `lon`                   DECIMAL(18,14) DEFAULT NULL            COMMENT '経度',
  `healthcare_expenses`   DECIMAL(12,2)  DEFAULT 0.00            COMMENT '医療費総額（USD）',
  `healthcare_coverage`   DECIMAL(12,2)  DEFAULT 0.00            COMMENT '保険適用総額（USD）',
  `income`                INT            DEFAULT NULL            COMMENT '年収（USD）'
) COMMENT = '患者マスタ — 人口統計・住所・保険関連の基本情報';


CREATE TABLE `providers` (
  `id`              VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '医療提供者の一意識別子（UUID）',
  `organization_id` VARCHAR(36)    DEFAULT NULL            COMMENT '所属医療機関ID',
  `name`            VARCHAR(255)   DEFAULT NULL            COMMENT '氏名',
  `gender`          CHAR(1)        DEFAULT NULL            COMMENT '性別（M=男性, F=女性）',
  `speciality`      VARCHAR(255)   DEFAULT NULL            COMMENT '専門分野',
  `address`         VARCHAR(255)   DEFAULT NULL            COMMENT '所在地（番地）',
  `city`            VARCHAR(100)   DEFAULT NULL            COMMENT '市区町村',
  `state`           VARCHAR(10)    DEFAULT NULL            COMMENT '州コード',
  `zip`             VARCHAR(15)    DEFAULT NULL            COMMENT '郵便番号',
  `lat`             DECIMAL(18,14) DEFAULT NULL            COMMENT '緯度',
  `lon`             DECIMAL(18,14) DEFAULT NULL            COMMENT '経度',
  `encounters`      INT            DEFAULT 0               COMMENT '受診件数',
  `procedures`      INT            DEFAULT 0               COMMENT '処置件数',

  CONSTRAINT `fk_providers_organization`
    FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`)
) COMMENT = '医療提供者マスタ — 医師・看護師等の情報';


-- ============================================================
-- 2. Encounter & Insurance Transition Tables
-- ============================================================

CREATE TABLE `encounters` (
  `id`                    VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '受診の一意識別子（UUID）',
  `start`                 DATETIME       NOT NULL               COMMENT '受診開始日時',
  `stop`                  DATETIME       DEFAULT NULL            COMMENT '受診終了日時',
  `patient_id`            VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `organization_id`       VARCHAR(36)    DEFAULT NULL            COMMENT '医療機関ID',
  `provider_id`           VARCHAR(36)    DEFAULT NULL            COMMENT '医療提供者ID',
  `payer_id`              VARCHAR(36)    DEFAULT NULL            COMMENT '保険者ID',
  `encounterclass`        VARCHAR(50)    DEFAULT NULL            COMMENT '受診区分（wellness / ambulatory / emergency 等）',
  `code`                  VARCHAR(20)    DEFAULT NULL            COMMENT 'SNOMED-CTコード',
  `description`           VARCHAR(500)   DEFAULT NULL            COMMENT '受診内容の説明',
  `base_encounter_cost`   DECIMAL(12,2)  DEFAULT NULL            COMMENT '基本受診費用（USD）',
  `total_claim_cost`      DECIMAL(12,2)  DEFAULT NULL            COMMENT '請求総額（USD）',
  `payer_coverage`        DECIMAL(12,2)  DEFAULT NULL            COMMENT '保険者負担額（USD）',
  `reasoncode`            VARCHAR(20)    DEFAULT NULL            COMMENT '受診理由コード（SNOMED-CT）',
  `reasondescription`     VARCHAR(500)   DEFAULT NULL            COMMENT '受診理由の説明',

  INDEX `idx_encounters_patient` (`patient_id`),
  INDEX `idx_encounters_date`    (`start`),

  CONSTRAINT `fk_encounters_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_encounters_organization`
    FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`),
  CONSTRAINT `fk_encounters_provider`
    FOREIGN KEY (`provider_id`) REFERENCES `providers`(`id`),
  CONSTRAINT `fk_encounters_payer`
    FOREIGN KEY (`payer_id`) REFERENCES `payers`(`id`)
) COMMENT = '受診記録 — 外来・入院・救急等すべての受診イベント';


CREATE TABLE `payer_transitions` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `member_id`       VARCHAR(36)    DEFAULT NULL            COMMENT '被保険者番号',
  `start_date`      DATETIME       DEFAULT NULL            COMMENT '加入開始日時',
  `end_date`        DATETIME       DEFAULT NULL            COMMENT '加入終了日時',
  `payer_id`        VARCHAR(36)    DEFAULT NULL            COMMENT '主保険者ID',
  `secondary_payer` VARCHAR(36)    DEFAULT NULL            COMMENT '副保険者ID',
  `plan_ownership`  VARCHAR(50)    DEFAULT NULL            COMMENT '加入区分（Self / Spouse 等）',
  `owner_name`      VARCHAR(255)   DEFAULT NULL            COMMENT '加入者名',

  INDEX `idx_payer_transitions_patient` (`patient_id`),

  CONSTRAINT `fk_payer_transitions_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_payer_transitions_payer`
    FOREIGN KEY (`payer_id`) REFERENCES `payers`(`id`)
) COMMENT = '保険加入履歴 — 患者の保険切替・移行記録';


-- ============================================================
-- 3. Clinical Data Tables
-- ============================================================

CREATE TABLE `conditions` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `start`           DATE           DEFAULT NULL            COMMENT '発症日',
  `stop`            DATE           DEFAULT NULL            COMMENT '治癒日（継続中はNULL）',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `system`          VARCHAR(255)   DEFAULT NULL            COMMENT 'コード体系URI（例: http://snomed.info/sct）',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT '疾患コード（SNOMED-CT）',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT '疾患名の説明',

  INDEX `idx_conditions_patient`   (`patient_id`),
  INDEX `idx_conditions_encounter` (`encounter_id`),
  INDEX `idx_conditions_code`      (`code`),

  CONSTRAINT `fk_conditions_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_conditions_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '疾患・状態記録 — 診断された病気や健康状態';


CREATE TABLE `allergies` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `start`           DATE           DEFAULT NULL            COMMENT 'アレルギー記録開始日',
  `stop`            DATE           DEFAULT NULL            COMMENT 'アレルギー解消日（継続中はNULL）',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT 'SNOMED-CTコード',
  `system`          VARCHAR(255)   DEFAULT NULL            COMMENT 'コード体系（SNOMED-CT等）',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT 'アレルゲンの説明',
  `type`            VARCHAR(50)    DEFAULT NULL            COMMENT 'アレルギー種別（allergy / intolerance）',
  `category`        VARCHAR(50)    DEFAULT NULL            COMMENT 'カテゴリ（food / environment / medication）',
  `reaction1`       VARCHAR(20)    DEFAULT NULL            COMMENT '反応1 コード',
  `description1`    VARCHAR(500)   DEFAULT NULL            COMMENT '反応1 の説明',
  `severity1`       VARCHAR(20)    DEFAULT NULL            COMMENT '反応1 の重症度（MILD / MODERATE / SEVERE）',
  `reaction2`       VARCHAR(20)    DEFAULT NULL            COMMENT '反応2 コード',
  `description2`    VARCHAR(500)   DEFAULT NULL            COMMENT '反応2 の説明',
  `severity2`       VARCHAR(20)    DEFAULT NULL            COMMENT '反応2 の重症度（MILD / MODERATE / SEVERE）',

  INDEX `idx_allergies_patient` (`patient_id`),

  CONSTRAINT `fk_allergies_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_allergies_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = 'アレルギー記録 — アレルゲンとアレルギー反応';


CREATE TABLE `medications` (
  `id`                  INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `start`               DATETIME       DEFAULT NULL            COMMENT '処方開始日時',
  `stop`                DATETIME       DEFAULT NULL            COMMENT '処方終了日時',
  `patient_id`          VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `payer_id`            VARCHAR(36)    DEFAULT NULL            COMMENT '保険者ID',
  `encounter_id`        VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`                VARCHAR(20)    DEFAULT NULL            COMMENT 'RxNormコード',
  `description`         VARCHAR(500)   DEFAULT NULL            COMMENT '薬品名・用量の説明',
  `base_cost`           DECIMAL(12,2)  DEFAULT NULL            COMMENT '基本費用（USD）',
  `payer_coverage`      DECIMAL(12,2)  DEFAULT NULL            COMMENT '保険者負担額（USD）',
  `dispenses`           INT            DEFAULT NULL            COMMENT '調剤回数',
  `totalcost`           DECIMAL(15,2)  DEFAULT NULL            COMMENT '合計費用（USD）',
  `reasoncode`          VARCHAR(20)    DEFAULT NULL            COMMENT '処方理由コード',
  `reasondescription`   VARCHAR(500)   DEFAULT NULL            COMMENT '処方理由の説明',

  INDEX `idx_medications_patient`   (`patient_id`),
  INDEX `idx_medications_encounter` (`encounter_id`),

  CONSTRAINT `fk_medications_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_medications_payer`
    FOREIGN KEY (`payer_id`) REFERENCES `payers`(`id`),
  CONSTRAINT `fk_medications_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '処方記録 — 薬剤の処方・調剤情報';


CREATE TABLE `procedures` (
  `id`                  INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `start`               DATETIME       DEFAULT NULL            COMMENT '処置開始日時',
  `stop`                DATETIME       DEFAULT NULL            COMMENT '処置終了日時',
  `patient_id`          VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`        VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `system`              VARCHAR(255)   DEFAULT NULL            COMMENT 'コード体系URI',
  `code`                VARCHAR(20)    DEFAULT NULL            COMMENT '処置コード（SNOMED-CT）',
  `description`         VARCHAR(500)   DEFAULT NULL            COMMENT '処置内容の説明',
  `base_cost`           DECIMAL(12,2)  DEFAULT NULL            COMMENT '基本費用（USD）',
  `reasoncode`          VARCHAR(20)    DEFAULT NULL            COMMENT '処置理由コード',
  `reasondescription`   VARCHAR(500)   DEFAULT NULL            COMMENT '処置理由の説明',

  INDEX `idx_procedures_patient`   (`patient_id`),
  INDEX `idx_procedures_encounter` (`encounter_id`),

  CONSTRAINT `fk_procedures_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_procedures_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '処置記録 — 手術・検査・治療等の医療処置';


CREATE TABLE `observations` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `date`            DATETIME       DEFAULT NULL            COMMENT '観察日時',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `category`        VARCHAR(50)    DEFAULT NULL            COMMENT 'カテゴリ（vital-signs / laboratory / social-history 等）',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT 'LOINCコード',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT '観察項目の説明',
  `value_text`      VARCHAR(500)   DEFAULT NULL            COMMENT '観察値（テキスト — 数値・文字列両方を格納）',
  `value_numeric`   DECIMAL(12,4)  DEFAULT NULL            COMMENT '観察値（数値型にパース可能な場合）',
  `units`           VARCHAR(50)    DEFAULT NULL            COMMENT '単位（cm / kg / mmHg 等）',
  `type`            VARCHAR(20)    DEFAULT NULL            COMMENT '値の型（numeric / text）',

  INDEX `idx_observations_patient`   (`patient_id`),
  INDEX `idx_observations_encounter` (`encounter_id`),
  INDEX `idx_observations_code`      (`code`),
  INDEX `idx_observations_date`      (`date`),

  CONSTRAINT `fk_observations_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_observations_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '観察・検査結果 — バイタルサイン・検査値・社会歴等';


CREATE TABLE `immunizations` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `date`            DATETIME       DEFAULT NULL            COMMENT '接種日時',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT 'CVXワクチンコード',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT 'ワクチン名の説明',
  `base_cost`       DECIMAL(12,2)  DEFAULT NULL            COMMENT '基本費用（USD）',

  INDEX `idx_immunizations_patient` (`patient_id`),

  CONSTRAINT `fk_immunizations_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_immunizations_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '予防接種記録 — ワクチン接種履歴';


CREATE TABLE `careplans` (
  `id`                  VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT 'ケアプランの一意識別子（UUID）',
  `start`               DATE           DEFAULT NULL            COMMENT 'ケアプラン開始日',
  `stop`                DATE           DEFAULT NULL            COMMENT 'ケアプラン終了日（継続中はNULL）',
  `patient_id`          VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`        VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`                VARCHAR(20)    DEFAULT NULL            COMMENT 'SNOMED-CTコード',
  `description`         VARCHAR(500)   DEFAULT NULL            COMMENT 'ケアプラン内容の説明',
  `reasoncode`          VARCHAR(20)    DEFAULT NULL            COMMENT 'ケアプラン理由コード',
  `reasondescription`   VARCHAR(500)   DEFAULT NULL            COMMENT 'ケアプラン理由の説明',

  INDEX `idx_careplans_patient` (`patient_id`),

  CONSTRAINT `fk_careplans_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_careplans_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = 'ケアプラン — 治療計画・管理計画';


CREATE TABLE `devices` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `start`           DATETIME       DEFAULT NULL            COMMENT '使用開始日時',
  `stop`            DATETIME       DEFAULT NULL            COMMENT '使用終了日時',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT 'SNOMED-CTコード',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT '医療機器名の説明',
  `udi`             VARCHAR(255)   DEFAULT NULL            COMMENT 'UDI（固有機器識別子）',

  INDEX `idx_devices_patient` (`patient_id`),

  CONSTRAINT `fk_devices_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_devices_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '医療機器記録 — 使用された医療機器・器具';


CREATE TABLE `imaging_studies` (
  `id`                    INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `study_id`              VARCHAR(36)    DEFAULT NULL            COMMENT '画像検査の識別子（UUID、複数インスタンスで共有）',
  `date`                  DATETIME       DEFAULT NULL            COMMENT '検査日時',
  `patient_id`            VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`          VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `series_uid`            VARCHAR(255)   DEFAULT NULL            COMMENT 'DICOMシリーズUID',
  `bodysite_code`         VARCHAR(20)    DEFAULT NULL            COMMENT '検査部位コード',
  `bodysite_description`  VARCHAR(255)   DEFAULT NULL            COMMENT '検査部位の説明',
  `modality_code`         VARCHAR(10)    DEFAULT NULL            COMMENT 'モダリティコード（DX / CT / MR 等）',
  `modality_description`  VARCHAR(100)   DEFAULT NULL            COMMENT 'モダリティの説明',
  `instance_uid`          VARCHAR(255)   DEFAULT NULL            COMMENT 'DICOMインスタンスUID',
  `sop_code`              VARCHAR(255)   DEFAULT NULL            COMMENT 'SOP ClassのUID',
  `sop_description`       VARCHAR(255)   DEFAULT NULL            COMMENT 'SOP Classの説明',
  `procedure_code`        VARCHAR(20)    DEFAULT NULL            COMMENT '検査処置コード',

  INDEX `idx_imaging_patient` (`patient_id`),

  CONSTRAINT `fk_imaging_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_imaging_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '画像検査記録 — X線・CT・MRI等のDICOM画像情報';


CREATE TABLE `supplies` (
  `id`              INT            NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '自動採番ID',
  `date`            DATE           DEFAULT NULL            COMMENT '供給日',
  `patient_id`      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `encounter_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '受診ID',
  `code`            VARCHAR(20)    DEFAULT NULL            COMMENT 'SNOMED-CTコード',
  `description`     VARCHAR(500)   DEFAULT NULL            COMMENT '物品名の説明',
  `quantity`        INT            DEFAULT NULL            COMMENT '数量',

  INDEX `idx_supplies_patient` (`patient_id`),

  CONSTRAINT `fk_supplies_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_supplies_encounter`
    FOREIGN KEY (`encounter_id`) REFERENCES `encounters`(`id`)
) COMMENT = '医療物品記録 — 使用された消耗品・物品';


-- ============================================================
-- 4. Billing / Claims Tables
-- ============================================================

CREATE TABLE `claims` (
  `id`                              VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '請求の一意識別子（UUID）',
  `patient_id`                      VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `provider_id`                     VARCHAR(36)    DEFAULT NULL            COMMENT '医療提供者ID',
  `primary_patient_insurance_id`    VARCHAR(36)    DEFAULT NULL            COMMENT '主保険の被保険者ID',
  `secondary_patient_insurance_id`  VARCHAR(36)    DEFAULT NULL            COMMENT '副保険の被保険者ID',
  `department_id`                   VARCHAR(10)    DEFAULT NULL            COMMENT '診療科ID',
  `patient_department_id`           VARCHAR(10)    DEFAULT NULL            COMMENT '患者診療科ID',
  `diagnosis1`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード1',
  `diagnosis2`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード2',
  `diagnosis3`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード3',
  `diagnosis4`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード4',
  `diagnosis5`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード5',
  `diagnosis6`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード6',
  `diagnosis7`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード7',
  `diagnosis8`                      VARCHAR(20)    DEFAULT NULL            COMMENT '診断コード8',
  `referring_provider_id`           VARCHAR(36)    DEFAULT NULL            COMMENT '紹介元医療提供者ID',
  `appointment_id`                  VARCHAR(36)    DEFAULT NULL            COMMENT '予約ID（受診ID）',
  `current_illness_date`            DATETIME       DEFAULT NULL            COMMENT '現病歴の開始日時',
  `service_date`                    DATETIME       DEFAULT NULL            COMMENT '診療日時',
  `supervising_provider_id`         VARCHAR(36)    DEFAULT NULL            COMMENT '指導医ID',
  `status1`                         VARCHAR(20)    DEFAULT NULL            COMMENT '主保険請求ステータス',
  `status2`                         VARCHAR(20)    DEFAULT NULL            COMMENT '副保険請求ステータス',
  `statusp`                         VARCHAR(20)    DEFAULT NULL            COMMENT '患者自己負担ステータス',
  `outstanding1`                    DECIMAL(12,2)  DEFAULT 0.00            COMMENT '主保険未払額（USD）',
  `outstanding2`                    DECIMAL(12,2)  DEFAULT 0.00            COMMENT '副保険未払額（USD）',
  `outstandingp`                    DECIMAL(12,2)  DEFAULT 0.00            COMMENT '患者自己未払額（USD）',
  `lastbilleddate1`                 DATETIME       DEFAULT NULL            COMMENT '主保険最終請求日時',
  `lastbilleddate2`                 DATETIME       DEFAULT NULL            COMMENT '副保険最終請求日時',
  `lastbilleddatep`                 DATETIME       DEFAULT NULL            COMMENT '患者最終請求日時',
  `healthcareclaimtypeid1`          INT            DEFAULT NULL            COMMENT '主保険請求種別ID',
  `healthcareclaimtypeid2`          INT            DEFAULT NULL            COMMENT '副保険請求種別ID',

  INDEX `idx_claims_patient`  (`patient_id`),
  INDEX `idx_claims_provider` (`provider_id`),
  INDEX `idx_claims_date`     (`service_date`),

  CONSTRAINT `fk_claims_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`),
  CONSTRAINT `fk_claims_provider`
    FOREIGN KEY (`provider_id`) REFERENCES `providers`(`id`)
) COMMENT = '保険請求 — 診療報酬請求（レセプト）の情報';


CREATE TABLE `claims_transactions` (
  `id`                        VARCHAR(36)    NOT NULL PRIMARY KEY COMMENT '取引の一意識別子（UUID）',
  `claim_id`                  VARCHAR(36)    NOT NULL               COMMENT '請求ID',
  `charge_id`                 INT            DEFAULT NULL            COMMENT '費目連番',
  `patient_id`                VARCHAR(36)    NOT NULL               COMMENT '患者ID',
  `type`                      VARCHAR(20)    DEFAULT NULL            COMMENT '取引種別（CHARGE / PAYMENT / TRANSFERIN / TRANSFEROUT）',
  `amount`                    DECIMAL(12,2)  DEFAULT NULL            COMMENT '金額（USD）',
  `method`                    VARCHAR(20)    DEFAULT NULL            COMMENT '支払方法（ECHECK 等）',
  `from_date`                 DATETIME       DEFAULT NULL            COMMENT '対象期間開始日時',
  `to_date`                   DATETIME       DEFAULT NULL            COMMENT '対象期間終了日時',
  `place_of_service`          VARCHAR(36)    DEFAULT NULL            COMMENT '診療場所ID（医療機関ID）',
  `procedure_code`            VARCHAR(20)    DEFAULT NULL            COMMENT '処置コード',
  `modifier1`                 VARCHAR(10)    DEFAULT NULL            COMMENT '修飾子1',
  `modifier2`                 VARCHAR(10)    DEFAULT NULL            COMMENT '修飾子2',
  `diagnosisref1`             INT            DEFAULT NULL            COMMENT '診断参照1',
  `diagnosisref2`             INT            DEFAULT NULL            COMMENT '診断参照2',
  `diagnosisref3`             INT            DEFAULT NULL            COMMENT '診断参照3',
  `diagnosisref4`             INT            DEFAULT NULL            COMMENT '診断参照4',
  `units`                     INT            DEFAULT NULL            COMMENT '数量',
  `department_id`             VARCHAR(10)    DEFAULT NULL            COMMENT '診療科ID',
  `notes`                     TEXT           DEFAULT NULL            COMMENT '備考',
  `unit_amount`               DECIMAL(12,2)  DEFAULT NULL            COMMENT '単価（USD）',
  `transfer_out_id`           VARCHAR(36)    DEFAULT NULL            COMMENT '転送先取引ID',
  `transfer_type`             VARCHAR(10)    DEFAULT NULL            COMMENT '転送区分',
  `payments`                  DECIMAL(12,2)  DEFAULT 0.00            COMMENT '支払額（USD）',
  `adjustments`               DECIMAL(12,2)  DEFAULT 0.00            COMMENT '調整額（USD）',
  `transfers`                 DECIMAL(12,2)  DEFAULT 0.00            COMMENT '転送額（USD）',
  `outstanding`               DECIMAL(12,2)  DEFAULT 0.00            COMMENT '未払額（USD）',
  `appointment_id`            VARCHAR(36)    DEFAULT NULL            COMMENT '予約ID（受診ID）',
  `line_note`                 TEXT           DEFAULT NULL            COMMENT '明細備考',
  `patient_insurance_id`      VARCHAR(36)    DEFAULT NULL            COMMENT '被保険者ID',
  `fee_schedule_id`           VARCHAR(10)    DEFAULT NULL            COMMENT '診療報酬表ID',
  `provider_id`               VARCHAR(36)    DEFAULT NULL            COMMENT '医療提供者ID',
  `supervising_provider_id`   VARCHAR(36)    DEFAULT NULL            COMMENT '指導医ID',

  INDEX `idx_claims_tx_claim`   (`claim_id`),
  INDEX `idx_claims_tx_patient` (`patient_id`),

  CONSTRAINT `fk_claims_tx_claim`
    FOREIGN KEY (`claim_id`) REFERENCES `claims`(`id`),
  CONSTRAINT `fk_claims_tx_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`)
) COMMENT = '請求明細取引 — 費用・支払・転送等の明細レベル取引';

-- ============================================================
-- Grant access to rag_user
-- ============================================================
GRANT ALL PRIVILEGES ON `synthea_db`.* TO 'rag_user'@'%';
FLUSH PRIVILEGES;
