# Data

The dataset for this project is `CaseStudy1.csv` (115 tinnitus patients). **It is not committed to this repository** — it was not supplied with the report, so it cannot be included here.

To run the analysis, place `CaseStudy1.csv` in this folder. It should contain these columns:

| Column | Description |
|---|---|
| `Group` | Control / Treatment |
| `Gender` | Coded 1 = Male, 2 = Female |
| `HHI_Score` | Hearing Handicap Inventory score |
| `GAD` | Generalized Anxiety Disorder score |
| `PHQ` | Patient Health Questionnaire (depression) score |
| `ISI` | Insomnia Severity Index |
| `SWLS` | Satisfaction With Life Scale |
| `Hyperacusis` | Sound-sensitivity score |
| `CFQ` | Cognitive Failures Questionnaire score |
| `Pre_TFI_Score` | Tinnitus Functional Index before treatment |
| `Post_TFI_Score` | Tinnitus Functional Index after treatment (has missing values — the script fills them with the column mean) |

The script (`code/tinnitus_analysis.R`) reads the file from this folder and creates the response variable `TFI_Reduction = Pre_TFI_Score − Post_TFI_Score` itself.
