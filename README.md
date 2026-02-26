# Customer Churn Analytics — Home Assignment

**Check Point | Senior Data Analyst | Tal Ilan**

---

## Repository Structure

```
├── data/
│   ├── charges_data.csv
│   ├── personal_data.csv
│   └── plan_data.csv
├── Queries.sql             # SQL queries (Parts 1–2)
├── README.md
├── Slides.pptx             # Slides (Part 4)
└── churn_analysis.ipynb    # Python notebook (Parts 1–3)
```

## Tools Used

- **SQL Server (SSMS)** — data preparation and analysis queries
- **Python (Jupyter Notebook)** — data preparation, analysis, and visualization
- **Libraries:** pandas, matplotlib, scipy

## Assumptions

- **Partner** refers to a spouse or domestic partner (Yes/No)
- **Dependents** refers to children or other dependents in the household (Yes/No)
- **charges_data** is the base table for all joins, as it contains the churn label for all 7,032 customers
- **455 missing charge values** (monthlyCharges and totalCharges) appear to be a data collection issue — their churn rate (~25.5%) is similar to the overall rate (~26.6%), indicating no systematic bias. These rows are included in all analyses except charge-based ones.

## Notes

- **Join strategy:** LEFT JOIN from charges_data preserves all customers with churn labels. Churn rate consistency was validated across all data coverage levels (~26% in each subset).
- **Tenure groups** are based on quartile boundaries (Q1=9, Q2=29, Q3=55), creating four business-meaningful segments.
- **Contract type** was selected as the additional churn dimension due to the highest spread (39.9pp) among all categorical variables, confirmed by Chi-square test (χ²=1,179.5, p<0.001).
- Every customer with plan data also has personal data — plan is effectively a subset of personal in this dataset.
