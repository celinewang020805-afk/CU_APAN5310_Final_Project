# CU_APAN5310_Final_Project

# ABC Foodmart Final Team Package

ABC Foodmart is a fictional grocery retail database project designed to support the analysis of store operations, staffing, inventory, purchasing, sales, returns, payments, and operating expenses. This package contains the final validated project files and deliverables prepared for the APAN 5310 Final Project.

## Folder Guide

- `01_Database`
  - Database Schema(`.sql`)
  - Schema Triggers(`.sql`)
  - ER Diagram(`.png`)
  - Lucidchart_ERD(`.pdf`)

- `02_Data/final_data`
  - 19 final validated CSV datasets
  - Approximately 36,000 sales transaction records

- `03_ETL`
  - Python data generation and ETL scripts(`.ipynb`)
  - Validation Summary Report(`.txt`)
  - Data Structure Mind Map (`.xmind` and `.pdf`)

- `04_Dashboard`
  - Metabase Dashboard Exports
  - Dashboard Screenshots(`.png`)

- `05_Final_Submission`
  - Final Report (`.docx` and `.pdf`)
  - Presentation Slides (`.pptx` and `.pdf`)

- `06_Notes_&_Feedback`
  - Handwritten Dashboard Feedback Notes(`.pdf`)(Not Important Just for Notes)


## Project Components

This project is organized into six main components:

1. **Database Design** – PostgreSQL relational schema, constraints, triggers, and ER diagram.
2. **Data** – Final validated CSV datasets used to populate and test the database.
3. **ETL Pipeline** – Python scripts for synthetic data generation, transformation, validation, and database loading.
4. **Dashboard** – Metabase dashboards and screenshots used to present operational and management insights.
5. **Final Submission** – Final written report and presentation materials.
6. **Notes & Feedback** – Supporting notes and dashboard feedback collected during project development.



## Quick Start
For reviewing or reproducing the project, follow this order:

1. Open `01_Database` to review the database schema, triggers, and ER diagram.
2. Review `02_Data/final_data` for the final 19 CSV datasets.
3. Use the Python files in `03_ETL` to understand how the data was generated, validated, and prepared for the database.
4. Review `04_Dashboard` for the Metabase dashboard outputs and screenshots.
5. Open `05_Final_Submission` for the final report and presentation.
6. Refer to `06_Notes_&_Feedback` for supporting feedback and development notes.



## Notes

- All business data in this project is synthetic and created for academic use.
- PostgreSQL was used as the relational database system.
- Metabase was used for dashboard development and visualization.


































# ABC Foodmart — SQL & Relational Database Final Project

## Project Overview

ABC Foodmart is a fictional neighborhood grocery chain originally operating two stores in Queens, New York, with plans to expand by opening three additional locations in Brooklyn.

The company historically managed information such as staffing, inventory, vendors, deliveries, sales, and operating expenses through spreadsheets and paper records. While this approach was manageable for two stores, the planned expansion created a need for a more centralized and scalable data system.

This project was developed as the final team project for **APAN 5310 — SQL & Relational Databases** at Columbia University.

Our team acted as database consultants hired to design a relational database system that could:

* Centralize operational data across multiple stores
* Reduce duplicated and inconsistent records
* Support inventory, purchasing, sales, staffing, and expense management
* Enforce data integrity and business rules
* Enable analysts to query the database directly
* Provide management with interactive dashboards and operational insights
* Create a foundation that could support future multi-store expansion and real-time reporting

---

## Business Problem

ABC Foodmart's main challenge was not simply storing more data, but creating a structured system that could support faster and more reliable operational decisions.

The project focused on questions such as:

* Which products are running low on inventory?
* Which products may be overstocked or slow-moving?
* Which products and categories generate the strongest sales?
* How should inventory purchasing be adjusted?
* Which vendors provide better pricing and more reliable deliveries?
* Are individual stores sufficiently staffed?
* How do staffing and operating expenses differ across locations?
* What are the sales and operating performance of each store?
* Are there unusual transactions, inventory movements, or other operational issues?
* How can managers access high-level information without writing SQL?

These questions guided the database schema, synthetic data design, analytical queries, and dashboard development.

---

## Project Scope

The final system integrates five major operational areas:

### 1. Store & Workforce Management

Tracks store locations, employee roles, employees, staff shifts, and time-off requests.

### 2. Product & Inventory Management

Tracks product categories, products, store-level inventory, and inventory adjustments.

### 3. Vendors & Purchasing

Tracks suppliers, vendor-product relationships, purchase orders, order items, and deliveries.

### 4. Sales & Returns

Tracks sales transactions, individual sale items, customer returns, and payments.

### 5. Operating Expenses

Tracks store-level operating expenses such as utilities, rent, maintenance, and other business costs.

---

## Database Design

The final PostgreSQL database contains **19 relational tables**:

### Store & Workforce

* `stores`
* `job_roles`
* `employees`
* `staff_shifts`
* `time_off_requests`

### Products & Inventory

* `product_categories`
* `products`
* `store_inventory`
* `inventory_adjustments`

### Vendors & Purchasing

* `vendors`
* `vendor_products`
* `purchase_orders`
* `purchase_order_items`
* `deliveries`

### Sales & Returns

* `sales_transactions`
* `sales_items`
* `customer_returns`
* `payments`

### Expenses

* `operating_expenses`

The database was designed to reduce redundancy and maintain clear relationships between business entities.

Reusable master data is stored separately and connected through primary and foreign keys. Transactional processes use header-detail structures such as:

* `sales_transactions` → `sales_items`
* `purchase_orders` → `purchase_order_items`

Associative tables are used where relationships contain their own business information:

* `store_inventory` represents the relationship between stores and products
* `vendor_products` represents the relationship between vendors and products

The final design follows normalization principles through **Third Normal Form (3NF)**.

---

## Data Integrity & Business Rules

The PostgreSQL schema uses:

* Primary Keys
* Foreign Keys
* `NOT NULL`
* `UNIQUE`
* `DEFAULT`
* `CHECK`
* `ON DELETE CASCADE`
* PostgreSQL Triggers

These mechanisms help prevent invalid or inconsistent data from entering the system.

Examples include:

* Preventing negative prices and invalid quantities
* Ensuring received quantities do not exceed ordered quantities
* Preventing duplicate vendor-product combinations
* Maintaining valid employee-store-role relationships
* Maintaining valid date sequences
* Preventing inventory balances from becoming negative

### Implemented Triggers

Three PostgreSQL triggers were included in the final schema:

#### `trg_apply_inventory_adjustment`

Updates the corresponding store inventory when a new inventory adjustment is inserted and rejects transactions that would create negative inventory.

#### `trg_reduce_inventory_after_sale`

Automatically creates a negative inventory adjustment when a sales item is inserted.

#### `trg_validate_purchase_order_vendor`

Ensures that the vendor-product selected in a purchase-order item belongs to the same vendor as the parent purchase order.

Together, these triggers help synchronize activity across sales, purchasing, and inventory records.

---

## Data Strategy

ABC Foodmart did not provide historical operational datasets for the project.

The team therefore treated the system as a **new operational database implementation rather than a data migration project**.

Synthetic operational data was generated to populate and test the relational schema.

The data-generation process covered:

* Stores
* Employees and job roles
* Staff shifts
* Time-off requests
* Product categories and products
* Store inventory
* Inventory adjustments
* Vendors
* Vendor-product relationships
* Purchase orders
* Purchase-order items
* Deliveries
* Sales transactions
* Sales items
* Returns
* Payments
* Operating expenses

A fixed random seed was used where appropriate to improve reproducibility.

---

## ETL & Data Validation

The data pipeline was designed around three major stages:

### 1. Data Generation

Generate realistic but fictional operational data based on predefined business rules.

### 2. Transformation & Validation

Validate and standardize:

* Column structures
* Data types
* Dates and timestamps
* Monetary values
* Missing values
* Duplicate records
* Primary and foreign key relationships
* Business-rule consistency

### 3. Database Loading

Load validated datasets into PostgreSQL while respecting foreign-key dependencies and relational constraints.

The first generated dataset revealed several logical inconsistencies that were not obvious from the schema alone.

Later iterations therefore focused heavily on:

* correcting unrealistic values,
* refining generation rules,
* reconciling relationships across tables,
* validating inventory and transaction logic,
* and ensuring that dashboard metrics were supported by reliable underlying data.

This became one of the most challenging and important parts of the project.

---

## Analytics & Business Insights

The relational database was designed not only for operational storage but also for analytical querying.

SQL analytical procedures were developed to support topics such as:

* Sales performance
* Product performance
* Category performance
* Store-level performance
* Inventory status
* Low-stock identification
* Overstock detection
* Vendor evaluation
* Purchasing activity
* Delivery performance
* Workforce analysis
* Operating expenses
* Returns and payment activity

These queries demonstrate how a centralized relational database can support faster cross-functional analysis than disconnected spreadsheets and paper records.

---

## Dashboard

A management-facing dashboard was developed in **Metabase**.

The dashboard translates relational database records into higher-level operational information for users who may not directly write SQL.

The design focuses on management questions related to:

* Sales
* Inventory
* Product performance
* Purchasing
* Vendors
* Staffing
* Expenses
* Store performance

The dashboard was iteratively reviewed and revised based on usability and business relevance.

### User Access Concept

The project supports two intended user groups:

**Analysts**

* Direct PostgreSQL access
* SQL analytical queries
* Python/database connections

**Managers / Executives**

* Interactive Metabase dashboards
* High-level operational KPIs
* Visual summaries without requiring SQL knowledge

---

## Deployment Considerations

The project currently demonstrates the database and dashboard as an academic prototype.

For a future production implementation, a cloud-based architecture would be preferable because ABC Foodmart is expanding from two to five stores and would benefit from centralized multi-location access.

Potential future improvements include:

* Cloud-hosted PostgreSQL
* Automated data ingestion
* Role-based access control
* Scheduled dashboard refreshes
* Views or materialized views for frequently used analytical queries
* Automated data quality monitoring
* More advanced demand forecasting
* Inventory replenishment recommendations
* Store-level profitability analysis

These features were considered as future extensions rather than fully implemented components of the current project.

---

## Project Timeline

The project was completed through five major weekly checkpoint stages.

| Stage           | Main Activity                                                                   |
| --------------- | ------------------------------------------------------------------------------- |
| **Week 1**      | Project scenario selection and initial business direction                       |
| **Week 2**      | Business requirements, team roles, and project planning                         |
| **Week 3**      | ERD, relational schema, integrity constraints, and triggers                     |
| **Week 4**      | Synthetic data generation, ETL, validation, and correction                      |
| **Week 5**      | Dashboard design, customer interaction planning, and performance considerations |
| **Final Stage** | Report integration, presentation preparation, final validation, and submission  |

The most challenging stages were **database schema design** and **data generation/validation**, because both required converting broad business requirements into internally consistent relational structures and realistic operational data.

---

## Team Responsibilities

### Xilin Wang — Project Coordinator & Final Integration

* Organized weekly team meetings
* Established internal deadlines
* Assigned and coordinated team tasks
* Summarized meetings and tracked project progress
* Defined parts of the early project direction and business logic
* Developed the first version of the synthetic data-generation process
* Defined several initial generation rules
* Reviewed checkpoint deliverables and provided revision feedback
* Contributed Section 6 of the final report
* Created the final presentation slides
* Wrote the final presentation script
* Coordinated final project integration and review

### Xiangzhou Tan — Database & Dashboard Lead

* Led the initial database schema development
* Contributed to relational database implementation
* Supported later-stage data corrections
* Led Metabase dashboard development
* Completed most dashboard implementation and configuration
* Published the final dashboard for external access
* Presented the Introduction and Conclusion portions of the final presentation

### Oracle — Report & Documentation Lead

* Completed the majority of the final written report
* Maintained project documentation across checkpoints
* Updated the report as the schema, ETL process, data-generation logic, and dashboard changed
* Documented generation-rule revisions and technical decisions

### Cloris — Data Validation & Schema Support

* Contributed to schema development and refinement
* Led later-stage data validation and correction
* Identified weaknesses in the initial synthetic data
* Worked with Xiangzhou to refine generation logic and resolve inconsistencies
* Supported final dataset validation

---

## Repository Structure

```text
ABC_Foodmart_Final_Team_Package/
│
├── 01_Database/
│   ├── Database Schema
│   ├── Triggers in Schema
│   └── ER Diagram
│
├── 02_Data/
│   └── final_data/
│       └── 19 authoritative CSV datasets
│
├── 03_ETL/
│   ├── Python Data Generation / ETL Code
│   ├── Validation Summary Report
│   └── Data Structure Mind Map
│
├── 04_Dashboard/
│   ├── Metabase Dashboard Exports
│   └── Dashboard Screenshots
│
├── 05_Final_Submission/
│   ├── Final Report
│   └── Final Presentation
│
└── 06_Notes_&_Feedback/
    └── Dashboard Feedback and Project Notes
```

---

## Quick Start

### 1. Review the database design

Start with:

`01_Database/`

Review the ER diagram and PostgreSQL schema to understand the 19-table relational structure.

### 2. Review the datasets

The authoritative final synthetic datasets are located in:

`02_Data/final_data/`

### 3. Review the ETL and validation process

See:

`03_ETL/`

This folder contains the data-generation logic, ETL materials, and validation documentation.

### 4. Review the dashboard

See:

`04_Dashboard/`

for dashboard exports and screenshots.

### 5. Review final deliverables

See:

`05_Final_Submission/`

for the completed report and presentation.

---

## Project Links

* **GitHub Repository:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project `

* **Full Synthetic Dataset:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project/tree/070627bde08b3dbd847a2fe7dcc8c2eb2cf0edc9/02_Data `
  `https://drive.google.com/drive/folders/1XZ3Zo5_3Stk0EV1tsyX9YEjXcNXMNlvv?usp=share_link`

* **Database Schema SQL:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project/blob/5b4653a3d41856daa96d80245e6d45fcbbd01674/01_Database/checkpoint3_schema_candidate.sql `

* **ER Diagram PDF:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project/blob/5b4653a3d41856daa96d80245e6d45fcbbd01674/01_Database/ER_Diagram.png `

* **Lucidchart ER Diagram:**
  `https://lucid.app/lucidchart/df33fdb0-a32d-48d7-8c5f-6392c9f83a02/edit?viewport_loc=-2235%2C-2794%2C4583%2C2779%2C0_0&invitationId=inv_0d4f1b21-aa1d-4f5d-818f-13758cd7b2bc `

* **ETL / Data Generation Code:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project/blob/5b4653a3d41856daa96d80245e6d45fcbbd01674/03_ETL_Data_Generation/ABC_Foodmart_Data_Generation.ipynb`

* **Public Metabase Dashboard:**
  `http://82.157.4.243:3000 `
  `(Username:3441136350@qq.com Password: Ty197399&)`

* **Final Report & Presentation:**
  `https://github.com/celinewang020805-afk/CU_APAN5310_Final_Project/blob/5b4653a3d41856daa96d80245e6d45fcbbd01674/05_Final_Submission/ABC_Foodmart_Pre.pdf `

---

## Course Context

This project was completed for:

**APAN 5310 — SQL & Relational Databases**
Columbia University
School of Professional Studies

The course project required teams to act as database consultants and develop a relational database solution that supports both:

* analysts who interact directly with the database through SQL and programming tools, and
* managers who access higher-level information through reports and interactive dashboards.

The project progressed through weekly checkpoints covering scenario selection, business requirements, relational database design, data preparation, and customer interaction/dashboard planning before the final presentation and submission.

---

## Key Takeaway

The project demonstrates how a fragmented operational environment can be translated into a centralized relational database architecture.

Rather than treating database development as only a table-creation exercise, the project connected:

**business requirements → relational design → synthetic data generation → data validation → SQL analytics → management dashboards**

The final system provides ABC Foodmart with a structured foundation for managing multi-store operations and illustrates how relational database design can support both operational reliability and business decision-making.
