# View payments information 

Providers can view up to date payment cut-off dates, upcoming payment dates, and check to see whether output payments have been made by DfE.

## Retrieve financial statements

```
GET /api/v1/statements
```

For more detailed information, see the ['Retrieve financial statements' endpoint documentation](/api/docs/v1#/Statements/get_api_v1_statements).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "statement",
      "attributes": {
        "month": "May",
        "year": "2022",
        "cohort": "2021",
        "cut_off_date": "2022-04-30",
        "payment_date": "2022-05-25",
        "paid": true,
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

## Retrieve a specific financial statement

```
GET /api/v1/statements/{id}
```

Providers can find statement IDs within previously submitted declaration response bodies.

For more detailed information, see the ['Retrieve a specific financial statement' endpoint documentation](/api/docs/v1#/Statements/get_api_v1_statements__id_).

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "statement",
    "attributes": {
      "month": "May",
      "year": "2022",
      "cohort": "2021",
      "cut_off_date": "2022-04-30",
      "payment_date": "2022-05-25",
      "paid": true,
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```
