# RAG Documents Overview

This folder contains 4 Japanese-language medical/insurance guideline documents used as the knowledge base for the RAG agent. Each document is designed to complement the Synthea SQL database, enabling combined RAG + SQL demo scenarios.

Thư mục này chứa 4 tài liệu hướng dẫn y tế/bảo hiểm bằng tiếng Nhật, dùng làm knowledge base cho RAG agent. Mỗi tài liệu được thiết kế để bổ trợ cho cơ sở dữ liệu SQL Synthea, phục vụ các kịch bản demo kết hợp RAG + SQL.

---

## 1. 糖尿病診療ガイドライン.txt
**Topic:** Diabetes Clinical Guidelines
**Chủ đề:** Hướng dẫn lâm sàng điều trị Tiểu đường

**Overview:**
A clinical reference document covering the full spectrum of diabetes management. Covers diagnostic criteria (HbA1c ≥ 6.5%, fasting glucose ≥ 126 mg/dL), classification (Type 1, Type 2, GDM), and treatment targets (HbA1c < 7.0%).

**Tổng quan:**
Tài liệu tham khảo lâm sàng bao quát toàn bộ quy trình quản lý bệnh tiểu đường. Bao gồm tiêu chuẩn chẩn đoán (HbA1c ≥ 6.5%, đường huyết lúc đói ≥ 126 mg/dL), phân loại bệnh (Type 1, Type 2, tiểu đường thai kỳ), và mục tiêu điều trị (HbA1c < 7.0%).

**Key sections / Các mục chính:**
- Diagnostic thresholds and pre-diabetes criteria
  — Ngưỡng chẩn đoán và tiêu chí tiền tiểu đường
- Pharmacotherapy: first-line (Metformin), add-ons (GLP-1 agonists, SGLT2 inhibitors, DPP-4 inhibitors, Insulin)
  — Dược lý trị liệu: thuốc hàng đầu (Metformin), thuốc bổ sung (đồng vận GLP-1, ức chế SGLT2, ức chế DPP-4, Insulin)
- Complication monitoring schedule: HbA1c, urinary albumin, retinal exam, foot check
  — Lịch theo dõi biến chứng: HbA1c, albumin niệu, khám đáy mắt, kiểm tra bàn chân
- Chronic complications: nephropathy, retinopathy, neuropathy, cardiovascular risk
  — Biến chứng mãn tính: bệnh thận, bệnh võng mạc, bệnh thần kinh, nguy cơ tim mạch
- Diet, exercise, and hypoglycemia management
  — Quản lý chế độ ăn, vận động và hạ đường huyết

**SQL tables it pairs with / Bảng SQL liên quan:** `conditions` (chẩn đoán tiểu đường), `medications` (đơn thuốc Metformin, Glipizide, Insulin), `observations` (chỉ số HbA1c)

---

## 2. 高血圧管理プロトコル.txt
**Topic:** Hypertension Management Protocol
**Chủ đề:** Phác đồ quản lý Tăng huyết áp

**Overview:**
A comprehensive hypertension management protocol covering classification, treatment targets, pharmacotherapy, and lifestyle interventions. Blood pressure categories range from Normal (< 120/80) to Stage III hypertension (≥ 180/110).

**Tổng quan:**
Phác đồ toàn diện về quản lý tăng huyết áp, bao gồm phân loại, mục tiêu điều trị, dược lý trị liệu và can thiệp lối sống. Các mức huyết áp từ Bình thường (< 120/80) đến Tăng huyết áp độ III (≥ 180/110).

**Key sections / Các mục chính:**
- Blood pressure classification table (6 categories)
  — Bảng phân loại huyết áp (6 mức độ)
- Primary vs. secondary hypertension distinction
  — Phân biệt tăng huyết áp nguyên phát và thứ phát
- Target blood pressure by patient group (general adults, elderly, diabetic, CKD, heart failure)
  — Mục tiêu huyết áp theo nhóm bệnh nhân (người lớn, người cao tuổi, tiểu đường, bệnh thận mãn, suy tim)
- Five first-line drug classes: ACE inhibitors (Lisinopril), ARBs (Losartan), Calcium channel blockers (Amlodipine), Thiazide diuretics (Hydrochlorothiazide), Beta-blockers (Atenolol)
  — 5 nhóm thuốc hàng đầu: ức chế ACE (Lisinopril), ức chế thụ thể Angiotensin-ARB (Losartan), chẹn kênh canxi (Amlodipine), lợi tiểu Thiazide (Hydrochlorothiazide), chẹn beta (Atenolol)
- Non-pharmacological interventions with expected mmHg reductions
  — Can thiệp không dùng thuốc kèm mức giảm mmHg kỳ vọng
- Home blood pressure monitoring guidelines and follow-up schedule
  — Hướng dẫn đo huyết áp tại nhà và lịch tái khám
- Hypertensive emergency vs. urgency management
  — Xử trí cơn tăng huyết áp khẩn cấp và cấp cứu

**SQL tables it pairs with / Bảng SQL liên quan:** `conditions` (chẩn đoán tăng huyết áp), `medications` (đơn thuốc hạ áp), `observations` (chỉ số huyết áp)

---

## 3. アレルギー・免疫療法ガイド.txt
**Topic:** Allergy and Immunotherapy Guide
**Chủ đề:** Hướng dẫn Dị ứng và Liệu pháp miễn dịch

**Overview:**
A practical allergy management guide covering drug allergies, food allergies, anaphylaxis protocols, vaccination schedules, and allergen immunotherapy. Emphasizes the most clinically significant drug allergens seen in the Synthea dataset.

**Tổng quan:**
Hướng dẫn thực hành quản lý dị ứng, bao gồm dị ứng thuốc, dị ứng thực phẩm, phác đồ xử trí sốc phản vệ, lịch tiêm chủng và liệu pháp miễn dịch dị nguyên. Tập trung vào các dị nguyên thuốc quan trọng nhất trong dataset Synthea.

**Key sections / Các mục chính:**
- Drug allergy profiles: Penicillin (cross-reactivity with cephalosporins), Sulfonamides, NSAIDs, ACE inhibitors, contrast media
  — Hồ sơ dị ứng thuốc: Penicillin (phản ứng chéo với cephalosporin), Sulfonamide, NSAIDs, ức chế ACE, thuốc cản quang
- Gell-Coombs classification of allergic reactions (Type I–IV)
  — Phân loại phản ứng dị ứng theo Gell-Coombs (Type I–IV): Type I tức thì (IgE), Type II gây độc tế bào, Type III phức hợp miễn dịch, Type IV chậm (tế bào T)
- Food allergens under Japanese labeling law (eggs, milk, wheat, peanuts, buckwheat, shellfish)
  — Dị nguyên thực phẩm theo luật ghi nhãn Nhật Bản (trứng, sữa, lúa mì, đậu phộng, kiều mạch, hải sản)
- Anaphylaxis diagnosis criteria, symptom checklist, and treatment protocol (Epinephrine 0.3–0.5 mg IM)
  — Tiêu chuẩn chẩn đoán sốc phản vệ, danh sách triệu chứng, phác đồ xử trí (Epinephrine 0.3–0.5 mg tiêm bắp)
- Adult vaccination schedule: Influenza, Pneumococcal, Shingles (Shingrix), COVID-19, Td, MMR
  — Lịch tiêm chủng người lớn: Cúm, Phế cầu khuẩn, Zona (Shingrix), COVID-19, Td, MMR
- Allergen immunotherapy (SCIT/SLIT): indications and duration (3–5 years)
  — Liệu pháp miễn dịch dị nguyên (SCIT: tiêm dưới da / SLIT: ngậm dưới lưỡi): chỉ định và thời gian điều trị (3–5 năm)
- Allergy testing methods: skin prick test, intradermal test, specific IgE
  — Các phương pháp xét nghiệm dị ứng: test lẩy da, test trong da, IgE đặc hiệu

**SQL tables it pairs with / Bảng SQL liên quan:** `allergies` (dị ứng Penicillin và các thuốc khác), `immunizations` (hồ sơ tiêm chủng), `conditions` (hen suyễn, viêm mũi dị ứng)

---

## 4. 医療保険と請求ガイド.txt
**Topic:** Health Insurance and Claims Guide
**Chủ đề:** Hướng dẫn Bảo hiểm y tế và Quy trình thanh toán

**Overview:**
An overview of the US healthcare insurance system structured around the Synthea dataset's payer model. Explains how Medicare, Medicaid, and private insurance differ, how claims are processed, and what drives covered vs. uncovered costs — directly mapping to tables in the database.

**Tổng quan:**
Tổng quan về hệ thống bảo hiểm y tế Mỹ, được xây dựng theo mô hình payer trong dataset Synthea. Giải thích sự khác biệt giữa Medicare, Medicaid và bảo hiểm tư nhân, quy trình xử lý hồ sơ bồi thường, và các yếu tố ảnh hưởng đến chi phí được bảo hiểm và không được bảo hiểm — ánh xạ trực tiếp vào các bảng trong database.

**Key sections / Các mục chính:**
- Insurance types: Medicare (Part A/B/C/D), Medicaid, Commercial (HMO/PPO/EPO), Uninsured
  — Các loại bảo hiểm: Medicare (Phần A/B/C/D dành cho người cao tuổi ≥ 65 tuổi), Medicaid (người thu nhập thấp), Bảo hiểm thương mại (HMO/PPO/EPO), Không có bảo hiểm
- Patient cost-sharing components: Premium, Deductible, Coinsurance, Copay, Out-of-Pocket Maximum
  — Các thành phần chi phí bệnh nhân tự trả: Phí bảo hiểm hàng tháng (Premium), Mức khấu trừ trước khi bảo hiểm chi trả (Deductible), Tỷ lệ đồng chi trả (Coinsurance), Phí cố định mỗi lần khám (Copay), Mức trần tự trả hàng năm (Out-of-Pocket Maximum)
- Coverage comparison table across insurance types (inpatient, outpatient, prescriptions, preventive care)
  — Bảng so sánh phạm vi bảo hiểm theo loại (nội trú, ngoại trú, thuốc kê đơn, chăm sóc dự phòng)
- Claims adjudication workflow: submission → review → EOB → patient billing
  — Quy trình xét duyệt hồ sơ bồi thường: nộp hồ sơ → xét duyệt → EOB (giải thích quyền lợi) → lập hóa đơn bệnh nhân
- Medical coding standards: ICD-10-CM, CPT, HCPCS, DRG
  — Tiêu chuẩn mã hóa y tế: ICD-10-CM (mã chẩn đoán), CPT (mã thủ thuật), HCPCS (mã dịch vụ Medicare), DRG (nhóm chẩn đoán liên quan — dùng cho thanh toán nội trú trọn gói)
- Common denial reasons and appeal process
  — Các lý do từ chối bồi thường phổ biến và quy trình kháng nghị
- Formulary tiers for prescription drug coverage (Tier 1 generic → Tier 5 specialty)
  — Danh mục thuốc theo bậc (Tier 1 thuốc generic → Tier 5 thuốc chuyên biệt/sinh học)
- Reference coverage rates by payer type (Medicare ~70–80%, Medicaid ~80–90%, Commercial ~60–85%)
  — Tỷ lệ bảo hiểm tham chiếu theo loại payer (Medicare ~70–80%, Medicaid ~80–90%, Bảo hiểm thương mại ~60–85%)

**SQL tables it pairs with / Bảng SQL liên quan:** `payers` (công ty bảo hiểm), `claims` (hồ sơ bồi thường), `claims_transactions` (các giao dịch chi tiết phí/thanh toán), `payer_transitions` (lịch sử bảo hiểm của bệnh nhân), `encounters` (PAYER_COVERAGE so với TOTAL_CLAIM_COST)

---

## Mapping: Documents × SQL Tables

| Document | conditions | medications | observations | allergies | immunizations | encounters | payers / claims |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 糖尿病診療ガイドライン | ✓ | ✓ | ✓ | | | | |
| 高血圧管理プロトコル | ✓ | ✓ | ✓ | | | | |
| アレルギー・免疫療法ガイド | ✓ | | | ✓ | ✓ | | |
| 医療保険と請求ガイド | | | | | | ✓ | ✓ |
