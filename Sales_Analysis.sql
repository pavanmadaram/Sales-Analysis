--Identify the top 3 customers in each country who have placed the most orders, ranked by the number of orders in descending order. In case of a tie, prioritize customers alphabetically by their unique ID.

WITH Customer_Details AS (
    SELECT 
        C.Country, 
        C.CustomerName, 
        C.CustomerID, 
        COUNT(O.OrderID) AS Number_of_Orders
    FROM Customers AS C
    JOIN Orders AS O
    ON C.CustomerID = O.CustomerID
    GROUP BY C.Country, C.CustomerName, C.CustomerID
),
Ranking AS (
    SELECT 
        Country, 
        CustomerName, 
        Number_of_Orders, 
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Number_of_Orders DESC, CustomerID ASC) AS Ranks
    FROM Customer_Details
)
SELECT 
    Country, 
    CustomerName, 
    Number_of_Orders
FROM Ranking
WHERE Ranks <= 3;


--Find the average spending of customers per city.

WITH Customer_OrderDetails AS (
    SELECT 
        O.OrderID, 
        O.CustomerID, 
        OD.ProductID, 
        OD.Quantity, 
        P.Price, 
        OD.Quantity * P.Price AS Total_Price
    FROM Orders AS O
    JOIN OrderDetails AS OD ON O.OrderID = OD.OrderID
    JOIN Products AS P ON OD.ProductID = P.ProductID
),
Total_Spending AS (
    SELECT 
        CustomerID, 
        SUM(Total_Price) AS Total_Spending
    FROM Customer_OrderDetails
    GROUP BY CustomerID
)
SELECT 
    C.City, 
    round(AVG(COALESCE(T.Total_Spending, 0)),2) AS Average_Spending
FROM Customers AS C
LEFT JOIN Total_Spending AS T ON C.CustomerID = T.CustomerID
GROUP BY C.City;


--Identify employees who handled the most orders and calculate their contribution to total sales.

WITH employee_sales AS (
    SELECT 
        O.EmployeeID,
        COUNT(O.OrderID) AS NumberOfOrders, 
        ROUND(SUM(OD.Quantity * P.Price), 2) AS Total_Price
    FROM Orders AS O
    JOIN OrderDetails AS OD ON O.OrderID = OD.OrderID
    JOIN Products AS P ON OD.ProductID = P.ProductID
    GROUP BY O.EmployeeID
    ORDER BY O.EmployeeID
),
EmployeesFullDetails AS (
    SELECT 
        E.EmployeeID, 
        CONCAT(E.LastName, ' ', E.FirstName) AS Full_Name, 
        COALESCE(NumberOfOrders, 0) AS TotalQuantity, 
        COALESCE(Total_Price, 0) AS TotalSales 
    FROM Employees AS E
    LEFT JOIN employee_sales AS ES ON E.EmployeeID = ES.EmployeeID
)
SELECT *, 
    CONCAT(ROUND(TotalSales / SUM(TotalSales) OVER() * 100, 2), '%') AS Contribution 
FROM EmployeesFullDetails;


--List employees and their average order size (quantity and revenue).

SELECT 
    O.EmployeeID,
    COUNT(O.OrderID) AS NumberOfOrders, 
    SUM(OD.Quantity) AS TotalQuantity,
    ROUND(SUM(OD.Quantity * P.Price), 2) AS TotalRevenue,
    ROUND(SUM(OD.Quantity) / COUNT(O.OrderID), 2) AS AverageQuantityPerOrder,
    ROUND(SUM(OD.Quantity * P.Price) / COUNT(O.OrderID), 2) AS AverageRevenuePerOrder
FROM Orders AS O
JOIN OrderDetails AS OD ON O.OrderID = OD.OrderID
JOIN Products AS P ON OD.ProductID = P.ProductID
GROUP BY O.EmployeeID
ORDER BY EmployeeID;

--Find the products that have contributed to the top 20% of total revenue.

WITH product_revenueDetails AS (
    SELECT 
        Od.ProductId,  
        ROUND(SUM(Od.Quantity * P.Price), 2) AS Total_revenue
    FROM Orderdetails AS Od
    JOIN Products AS P ON Od.ProductId = P.ProductId
    GROUP BY Od.ProductId
),
total_revenue AS (
    SELECT SUM(Total_revenue) AS TotalRevenue FROM product_revenueDetails
),
contributions AS (
    SELECT 
        ProductId, 
        Total_revenue, 
        ROUND(Total_revenue / (SELECT TotalRevenue FROM total_revenue) * 100, 2) AS contribution_percentage
    FROM product_revenueDetails
),
rolling AS (
    SELECT 
        ProductId, 
        Total_revenue, 
        contribution_percentage,
        SUM(contribution_percentage) OVER (ORDER BY Total_revenue DESC) AS rolling_sum
    FROM contributions
)
SELECT 
    ProductId 
FROM rolling
WHERE rolling_sum <= 20;

--List products that have never been ordered or are out of stock.

SELECT ProductId
FROM Products
WHERE ProductId NOT IN (SELECT DISTINCT ProductId FROM Orderdetails);


--Identify the shipper who handled the highest revenue-generating orders.

WITH order_revenue AS (
    SELECT 
        O.OrderID,
        O.ShipperID,
        ROUND(SUM(OD.Quantity * P.Price), 2) AS TotalRevenue
    FROM Orders AS O
    JOIN OrderDetails AS OD ON O.OrderID = OD.OrderID
    JOIN Products AS P ON OD.ProductID = P.ProductID
    GROUP BY O.OrderID, O.ShipperID
),
highest_revenue_shipper AS (
    SELECT 
        ShipperID,
        MAX(TotalRevenue) AS MaxRevenue
    FROM order_revenue
    GROUP BY ShipperID
)
SELECT 
    S.ShipperName,
    HR.MaxRevenue
FROM highest_revenue_shipper AS HR
JOIN Shippers AS S ON HR.ShipperID = S.ShipperID
ORDER BY HR.MaxRevenue DESC
LIMIT 1;


--Retrieve all orders along with customer name, employee details, and shipper information.

Select 
	O.OrderId,
    C.customerId,
    Concat(E.firstname, " ", E.lastname) as FullName,
    S.Shippername,
    O.Neworderdate
from 
	Orders as O
join 
	Customers as C
on 
	O.customerId = C.customerId
join 
	employees as E
on 
	O.employeeId = E.employeeId
join 
	Shippers as S
on 
	O.shipperId = S.ShipperId
Order by 
	customerId asc


--Find the most frequently ordered product by customer and employee.

WITH ProductDetails AS (
    SELECT
        O.CustomerID,
        OD.ProductID,
        E.EmployeeID,
        SUM(OD.Quantity) AS TotalQuantity,
        DENSE_RANK() OVER (
            PARTITION BY O.CustomerID 
            ORDER BY SUM(OD.Quantity) DESC, OD.ProductID ASC
        ) AS Ranks
    FROM Orders AS O
    JOIN OrderDetails AS OD ON O.OrderID = OD.OrderID
    JOIN Employees AS E ON O.EmployeeID = E.EmployeeID
    GROUP BY O.CustomerID, OD.ProductID, E.EmployeeID
),
TopProducts AS (
    SELECT
        PD.CustomerID,
        C.CustomerName,
        PD.EmployeeID,
        CONCAT(E.LastName, ' ', E.FirstName) AS EmployeeName,
        PD.ProductID,
        P.ProductName,
        PD.TotalQuantity
    FROM ProductDetails AS PD
    JOIN Customers AS C ON PD.CustomerID = C.CustomerID
    JOIN Employees AS E ON PD.EmployeeID = E.EmployeeID
    JOIN Products AS P ON PD.ProductID = P.ProductID
    WHERE PD.Ranks = 1
)
SELECT * 
FROM TopProducts
ORDER BY CustomerID, EmployeeID;


--Display the top 5 suppliers contributing the most to revenue, along with their product categories.

WITH SupplierRevenue AS (
    SELECT 
        P.SupplierID,
        P.CategoryID,
        ROUND(SUM(OD.Quantity * P.Price), 2) AS TotalRevenue,
        DENSE_RANK() OVER (PARTITION BY P.SupplierID ORDER BY SUM(OD.Quantity * P.Price) DESC) AS Ranks
    FROM 
        OrderDetails AS OD
    JOIN 
        Products AS P
    ON 
        OD.ProductID = P.ProductID
    GROUP BY 
        P.SupplierID, P.CategoryID
),
TopSupplierCategory AS (
    SELECT 
        SR.SupplierID, 
        S.SupplierName, 
        SR.TotalRevenue, 
        SR.CategoryID, 
        C.CategoryName
    FROM 
        SupplierRevenue AS SR
    JOIN 
        Suppliers AS S
    ON 
        SR.SupplierID = S.SupplierID
    JOIN 
        Category AS C
    ON 
        SR.CategoryID = C.CategoryID
    WHERE 
        SR.Ranks = 1
)
SELECT 
    SupplierID, 
    SupplierName, 
    TotalRevenue, 
    CategoryID, 
    CategoryName
FROM 
    TopSupplierCategory
ORDER BY 
    TotalRevenue DESC
LIMIT 5;

--List categories that have the highest number of products ordered.

SELECT 
    P.CategoryID, 
    CT.CategoryName, 
    SUM(OD.Quantity) AS TotalProductsOrdered
FROM 
    OrderDetails AS OD
JOIN 
    Products AS P
ON 
    OD.ProductID = P.ProductID
JOIN 
    Category AS CT
ON 
    P.CategoryID = CT.CategoryID
GROUP BY 
    P.CategoryID, CT.CategoryName
ORDER BY 
    TotalProductsOrdered DESC;

--Identify orders that include products associated with more than one category, and list the product name along with the corresponding supplier details.

WITH cte AS (
    SELECT   
        Od.OrderId,      
        P.ProductName,     
        S.SupplierName,
        C.CategoryID
    FROM   
        OrderDetails AS Od 
    JOIN   
        Products AS P 
    ON   
        Od.ProductID = P.ProductID 
    JOIN   
        Suppliers AS S 
    ON   
        P.SupplierID = S.SupplierID
    JOIN
        Category AS C
    ON
        P.CategoryID = C.CategoryID
), category_counts AS (
    SELECT 
        OrderID,
        COUNT(DISTINCT CategoryID) AS category_count
    FROM 
        cte
    GROUP BY 
        OrderID
)
SELECT 
    cte.OrderID, 
    cte.ProductName, 
    cte.SupplierName 
FROM 
    cte
JOIN 
    category_counts 
ON 
    cte.OrderID = category_counts.OrderID
WHERE 
    category_counts.category_count > 1;

--Rank categories by total revenue and identify the top 3.

WITH rankings AS (
    SELECT 
        P.categoryid,
        ROUND(SUM(Od.Quantity * P.price), 2) AS Total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(Od.Quantity * P.price) DESC) AS category_rank
    FROM 
        orderdetails AS Od
    JOIN 
        products AS P
    ON 
        Od.productid = P.productid
    GROUP BY
        P.categoryid
    ORDER BY 
        Total_revenue DESC
)
SELECT 
    R.categoryid, 
    C.categoryname, 
    R.total_revenue, 
    R.category_rank
FROM 
    rankings AS R
JOIN 
    category AS C
ON 
    R.categoryid = C.categoryid
WHERE 
    category_rank <= 3
ORDER BY 
    category_rank;
    
--Rank customers by their total spend

SELECT 
    C.CustomerId,
    C.Customername, 
    ROUND(SUM(Od.Quantity * P.Price), 2) AS total_spent,
    DENSE_RANK() OVER (ORDER BY SUM(Od.Quantity * P.Price) DESC) AS Customer_rank
FROM
    Orders AS O
LEFT JOIN 
    Customers AS C ON O.CustomerId = C.CustomerId
JOIN 
    Orderdetails AS Od ON O.OrderId = Od.OrderId
JOIN 
    Products AS P ON Od.ProductId = P.ProductId
GROUP BY 
    C.CustomerId, C.Customername
ORDER BY 
    total_spent DESC;

--Calculate monthly revenue and compare it with the previous month for trends.

WITH MonthlyRevenue AS (
    SELECT 
        YEAR(O.NewOrderDate) AS revenue_year,
        MONTH(O.NewOrderDate) AS revenue_month,
        round(SUM(Od.Quantity * P.Price),2) AS Total_revenue
    FROM 
        Orders AS O
    JOIN 
        Orderdetails AS Od ON O.OrderId = Od.OrderId
    JOIN 
        Products AS P ON Od.ProductId = P.ProductId
    GROUP BY 
        YEAR(O.NewOrderDate), MONTH(O.NewOrderDate)
)
SELECT 
    revenue_year,
    revenue_month,
    Total_revenue,
    Round(LAG(Total_revenue) OVER (ORDER BY revenue_year, revenue_month),2) AS Previous_month_revenue,
    round(Total_revenue - LAG(Total_revenue) OVER (ORDER BY revenue_year, revenue_month),2) AS Revenue_change
FROM 
    MonthlyRevenue
ORDER BY 
    revenue_year, revenue_month;


--Identify the peak sales period for each product.

with Months as(
Select
    Od.Productid,
    P.productname,
    extract(month from O.Neworderdate) as Months,
    extract(year from o.neworderdate) as Years,
    Sum(Od.Quantity * P.price) as Total_revenue
From
	Orders as O
Join 
	Orderdetails as Od
on
	O.Orderid = od.orderid
join 
	products as P
On
	Od.productid = P.productid
Group by 
	years, 
    Months, 
    productid
)
, ranks as (
Select 
	ProductId,
    Productname,
    Months as Peakmonth,
    Years as Peakyear,
    Total_revenue,
    dense_rank() over(partition by productid order by Total_revenue desc) as Ranks
From
	Months)
Select ProductId, Productname, PeakMonth, Peakyear, total_revenue
from ranks 
where ranks = 1


--Find customers who placed orders above the average order value.

WITH cte AS (
    SELECT 
        C.customerid, 
        C.customername,
        ROUND(SUM(Od.quantity * P.price), 2) AS total_spent
    FROM 
        orders AS O
    LEFT JOIN 
        customers AS C ON O.customerid = C.customerid
    JOIN 
        orderdetails AS Od ON Od.orderid = O.orderid
    JOIN 
        products AS P ON Od.productid = P.productid
    GROUP BY 
        C.customerid
    ORDER BY 
        total_spent DESC
)
SELECT * 
FROM cte
WHERE total_spent > (
    SELECT 
        ROUND(SUM(Od.Quantity * P.price) / COUNT(DISTINCT O.Orderid), 2) AS t
    FROM 
        orders AS O
    JOIN 
        orderdetails AS Od ON O.orderid = Od.orderid 
    JOIN 
        products AS P ON Od.productid = P.productid
);

--List customers whose orders include products from at least three different categories.

WITH cte AS (
    SELECT 
        C.customerid,
        C.customername,
        COUNT(DISTINCT P.categoryid) AS No_of_Categories
    FROM 
        Orders AS O
    LEFT JOIN 
        Customers AS C
    ON O.customerid = C.customerid
    JOIN orderdetails AS OD
    ON OD.orderid = O.orderid
    JOIN products AS P
    ON OD.productid = P.productid
    GROUP BY C.customerid, C.customername
)
SELECT customerid, customername, No_of_Categories
FROM cte
WHERE No_of_Categories >= 3
ORDER BY customerid ASC;


--List suppliers with products not ordered in the past six months.

SELECT 
    S.supplierid,
    S.suppliername
FROM 
    suppliers AS S
WHERE 
    S.supplierid NOT IN (
        SELECT DISTINCT P.supplierid
        FROM 
            Orders AS O
        JOIN 
            orderdetails AS OD
            ON O.orderid = OD.orderid
        JOIN 
            products AS P
            ON OD.productid = P.productid
        WHERE 
            O.Neworderdate >= (
                SELECT MAX(Neworderdate) - INTERVAL 6 MONTH
                FROM Orders
            )
    );


--Calculate the cumulative sales for each day over time.

with daily_sales as(
Select 
    O.NewOrderDate,
    round(SUm(Od.Quantity * P.Price),2) as total_revenue
from 
	Orderdetails as OD
left join 
	orders as O
On 
	Od.orderid = O.orderid
join 
	products as P
on 
	P.productid = Od.productid
Group by 
	O.neworderdate)
select 
	neworderdate, 
    total_revenue,
    round(sum(total_revenue) over(order by neworderdate asc),2) as cumulative_sales
from 
	daily_sales


--Compute the cumulative revenue by category and product.

with category_details as(
Select 
	C.categoryname,
    P.productname,
    O.Neworderdate, 
    round(Sum(Od.Quantity * P.price),2) as total_spent
from 
	Orderdetails as Od
left join 
	Orders as O
on 
	Od.orderid = O.orderid
join 
	products as P
on 
	P.productid = od.productid
join 
	category as C
on
	p.categoryid = c.categoryid
Group by
	c.Categoryname, P.productname, O.neworderdate
Order by 
	C.categoryname asc, O.neworderdate asc)
select 
	categoryname,
    Productname,
    Neworderdate as Orderdate,
    total_spent,
    round(sum(total_spent) over(partition by categoryname order by neworderdate),0) as Cumulative_sales
from 
	category_details


--Rank customers by their recency, frequency, and monetary (RFM) values.

WITH customer_details AS (
    SELECT 
        C.customername,
        C.customerid,
        MAX(O.Neworderdate) AS latest_purchasedate,
        ROUND(SUM(Od.quantity * P.price), 2) AS Monetary,
        COUNT(DISTINCT O.Orderid) AS Frequency
    FROM 
        orders AS O
    LEFT JOIN 
        Customers AS C ON C.customerid = O.customerid
    JOIN 
        orderdetails AS Od ON Od.orderid = O.orderid
    JOIN 
        Products AS P ON Od.productid = P.productid
    GROUP BY 
        O.Customerid
),
rfm_assignment AS (
    SELECT 
        customerid, 
        customername,
        DATEDIFF((SELECT MAX(neworderdate) FROM orders), latest_purchasedate) AS Recency,
        NTILE(5) OVER (ORDER BY DATEDIFF((SELECT MAX(neworderdate) FROM orders), latest_purchasedate) ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS frequency_score,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS monetary_score
    FROM 
        customer_details
)
SELECT
    customerid, 
    customername,
    recency_score + frequency_score + monetary_score AS rfm_score
FROM 
    rfm_assignment 
ORDER BY 
    rfm_score DESC;


--Find customers who have consistently placed orders every month for the last six months.

WITH Last_Six_Months AS (
    SELECT 
        CustomerId,
        CONCAT(YEAR(Neworderdate), '-', MONTH(Neworderdate)) AS yr_mon
    FROM 
        orders
    WHERE
        Neworderdate >= DATE_SUB(
            (SELECT MAX(Neworderdate) FROM orders), INTERVAL 6 MONTH
        )
    GROUP BY 
        CustomerId, yr_mon
),
Customer_Order_Count AS (
    SELECT 
        CustomerId,
        COUNT(DISTINCT yr_mon) AS months_with_orders
    FROM 
        Last_Six_Months
    GROUP BY 
        CustomerId
)
SELECT 
    C.CustomerId
FROM 
    Customer_Order_Count C
WHERE 
    C.months_with_orders = 6
ORDER BY 
    C.CustomerId;

--Categorize customers into "High Value," "Medium Value," and "Low Value" based on their total spend.

with customer_revenue as(
Select 
	O.customerid, 
    round(Sum(Od.Quantity * P.price),2) as Total_Spent
from
	Orders as O
join 
	Orderdetails as Od
on 
	O.orderid = Od.orderid
join 
	products as P
on
	P.productid = od.productid
group by 
	customerid)
, ranks_details as(
Select 
	customerid, 
    total_spent,
    ntile(5) over(order by total_spent desc) as spend_ranks
from customer_revenue)
select 
	customerid, 
    total_spent, 
    case 
		when Spend_ranks = 1 then "High Value Customer"
        when Spend_ranks = 2 or Spend_ranks = 3 then "Medium Value Customer"
        else "Low Value Customer" end as CustomerCategory
from ranks_Details


--Retrieve orders where the total order value exceeds the average order value for its respective month.

with Monthly_averageOrderValue as(
Select 
    Year(O.Neworderdate) as yrs,
	Month(O.Neworderdate) as months,
    Round(Sum(Od.Quantity * P.price) / Count(distinct O.Orderid),2) as Average_value
from
	Orders as O
Join 
	orderdetails as Od
on 
	O.orderid = Od.orderid
Join
	products as P
on
	od.productid = p.productid
group by
	Yrs,
    Months)
, All_Cx_details as(
Select 
	O.OrderId,
	Year(O.Neworderdate) as yrs,
	Month(O.Neworderdate) as months,
    Sum(Od.Quantity * P.price) as Total_spent
from
	Orders as O
Join 
	orderdetails as Od
on 
	O.orderid = Od.orderid
Join
	products as P
on
	od.productid = p.productid
group by
	O.orderid)
Select
	C.OrderId,
    C.yrs,
    C.months,
    C.Total_spent
from
	All_Cx_details as C
join 
	Monthly_averageOrderValue as A
On 
	A.yrs = C.yrs and A.months = C.months
where C.Total_spent > A.Average_value
