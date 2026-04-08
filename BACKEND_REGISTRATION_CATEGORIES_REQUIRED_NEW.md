# Registration Categories Required (Backend Handoff)

This file defines the **required categories** for the mobile registration flow.

Base URL: `https://a-plus.anmka.com/api`  
Endpoint: `GET /categories`

---

## Required top-level categories (exact set)

Backend should return these 7 categories so users can select them in Register:

1. بشري
2. اسنان
3. علاج طبيعي
4. صيدله
5. تمريض
6. علوم
7. تربية

Recommended: set both `name` and `name_ar` to the same Arabic label.

---

## Required response shape

Registration screen reads categories from:

- `data` as a list **or**
- `data.categories` list

Each category item should include at least:

- `id` (string, stable UUID)
- `name` (string)
- `name_ar` (string)
- `subcategories` (array, can be empty)

---

## Required subcategories for all categories

Each of the 7 categories above must include the same 6 subcategories:

1. الأولى
2. الثانية
3. الثالثة
4. الرابعة
5. الخامسة
6. السادسة

This is required for **all categories** (not optional).

The app reads subcategories from the first available key:

- `subcategories` (preferred)
- `sub_categories`
- `children`

Backend must provide valid subcategory objects with stable IDs so register can send:

- `category_id`
- `subcategory_id`

for every registration.

---

## Example JSON (category + required subcategories)

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "name": "بشري",
      "name_ar": "بشري",
      "subcategories": [
        { "id": "sub-1", "name": "الأولى", "name_ar": "الأولى" },
        { "id": "sub-2", "name": "الثانية", "name_ar": "الثانية" },
        { "id": "sub-3", "name": "الثالثة", "name_ar": "الثالثة" },
        { "id": "sub-4", "name": "الرابعة", "name_ar": "الرابعة" },
        { "id": "sub-5", "name": "الخامسة", "name_ar": "الخامسة" },
        { "id": "sub-6", "name": "السادسة", "name_ar": "السادسة" }
      ]
    }
  ]
}
```

---

## Mobile status

- Register category/subcategory picker is already implemented in app.
- Once backend returns the 7 categories above and the required 6 subcategories for each category, users will be able to select both directly in Register.
