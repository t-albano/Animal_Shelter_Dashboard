# Data Documentation

Data was collected from Dallas OpenData. The datasets were the October 2018 through April 2023 datasets.
They were compiled and cleaned for visualization. Then smaller tables were created from this dataset to be used in Tableau.


`animal_shelter_cleaned.xlsx` variables:
* **ID:** String. Unique ID given to each animal. Some IDs will have multiple entries.

* **ANIMAL_TYPE:** String. Type of animal. May be either `CAT` or `DOG`.

* **INTAKE:** String. May state `STRAY`, `OWNER SURRENDER`, `TRANSFER`, `FOSTER`, or `CONFISCATED`.

* **IN_DATE:** Date (in Excel mm/dd/yyyy format). From October 1, 2018 to April 7, 2022.

* **OUTCOME:** String. May state `ADOPTION`, `FOSTER`, `TRANSFER`, `EUTHANIZED`, or `RETURNED TO OWNER`

* **OUT_DATE:** Date (in Excel mm/dd/yyyy format). From October 1, 2018 to April 7, 2022.

* **in_month:** Integer. Numerical representation of month.

* **in_year:** Integer. Numberal representation of year in yyyy format.

* **out_month:** Integer. Numerical representation of month.

* **out_year:** Integer. Numberal representation of year in yyyy format.

* **days_in:** Integer. Difference between `OUT_DATE` and `IN_DATE`.
