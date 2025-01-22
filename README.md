# Sales Analysis SQL Project

This project demonstrates advanced SQL queries for analyzing sales data, focusing on deriving actionable insights such as identifying top customers, ranking them, and exploring sales trends. The analysis highlights proficiency in SQL, showcasing skills in writing optimized queries, using advanced functions, and performing data-driven analysis.

## Dataset

The dataset consists of the following tables:

### 1. **Category**
- **Columns**: `CategoryID`, `CategoryName`, `Description`
- Stores information about product categories.

### 2. **Customers**
- **Columns**: `CustomerID`, `CustomerName`, `ContactName`, `Address`, `City`, `PostalCode`, `Country`
- Contains customer details such as name, address, and contact information.

### 3. **Employees**
- **Columns**: `EmployeeID`, `LastName`, `FirstName`, `BirthDate`, `Photo`, `Notes`
- Tracks employee information.

### 4. **OrderDetails**
- **Columns**: `OrderDetailID`, `OrderID`, `ProductID`, `Quantity`
- Represents the details of each order, including product and quantity.

### 5. **Orders**
- **Columns**: `OrderID`, `CustomerID`, `EmployeeID`, `ShipperID`, `NewOrderDate`
- Tracks orders made by customers.

### 6. **Products**
- **Columns**: `ProductID`, `ProductName`, `SupplierID`, `CategoryID`, `Unit`, `Price`
- Contains product details including category and supplier.

### 7. **Shippers**
- **Columns**: `ShipperID`, `ShipperName`, `Phone`
- Stores information about shipping companies.

### 8. **Suppliers**
- **Columns**: `SupplierID`, `SupplierName`, `ContactName`, `Address`, `City`, `PostalCode`, `Country`, `Phone`
- Contains supplier details.

## Features
- **Customer Insights**: Identify the top 3 customers in each country based on the number of orders. Includes tie-breaking logic, prioritizing customers alphabetically by their unique IDs.
- **Data Aggregation**: Leverages SQL functions such as `COUNT`, `RANK`, and `WITH (Common Table Expressions)` for efficient data processing.
- **Ranking and Filtering**: Implements ranking logic using window functions to prioritize customers.
- **Scalability**: Queries are structured to handle large datasets efficiently.

## Technologies Used
- **SQL**
- **MySQL**

## How to Use
1. **Setup**: Load the relevant datasets into your SQL database.
2. **Execute Queries**: Run the provided SQL script to analyze the data.
3. **Customize**: Modify queries as needed to suit specific datasets or analysis goals.

## Learning Outcomes
- Advanced SQL query writing skills.
- Data aggregation and ranking techniques.
- Insights generation from sales data.

## Applications
- Customer segmentation and targeting.
- Sales performance analysis.
- Business decision-making based on data-driven insights.
