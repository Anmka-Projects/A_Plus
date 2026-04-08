# Categories API — expected data for registration (Rig Tech mobile)

The student registration screen loads **`GET /api/categories`** (same path as today: `ApiEndpoints.categories`). The mobile app **filters and orders** the response to match the lists below. The backend should persist these records with stable UUIDs so `category_id` / `subcategory_id` on register remain valid.

Base URL: `https://rigtech-training-academy.anmka.com/api`  
Endpoint: **`GET /categories`**

---

## 1. Categories (exact set, this order)

Each category must be identifiable by `name` or `name_ar` (the app matches either). Recommended: set both to the same Arabic label.

| # | Arabic name (canonical) |
|---|-------------------------|
| 1 | بشري |
| 2 | اسنان |
| 3 | علاج طبيعي |
| 4 | صيدله |
| 5 | تمريض |
| 6 | علوم |
| 7 | تربية |

**Spelling variants the app also accepts** (for matching only; UI shows the canonical name above):

- **اسنان**: `أسنان`, `الاسنان`, `الأسنان`
- **صيدله**: `صيدلة`, `الصيدلة`
- **بشري**: `البشري`
- **علاج طبيعي**: `العلاج الطبيعي`
- **تمريض**: `التمريض`
- **علوم**: `العلوم`
- **تربية**: `التربية`

---

## 2. Subcategories (per category)

Every category should expose the **same six** subcategories (academic years), nested on each category object.

**Canonical labels (display order):**

1. الأولى  
2. الثانية  
3. الثالثة  
4. الرابعة  
5. الخامسة  
6. السادسة  

**Matching variants:**

- **الأولى**: `الاولى` (without hamza)
- **الرابعة**: `الرايعة`, `الرابعه` (common typos / alternates — app normalizes display to **الرابعة**)

### Nesting keys (any one is fine)

The app reads subcategories from the first present key:

- `subcategories` *(preferred)*  
- `sub_categories`  
- `children`

---

## 3. Example JSON shape

```json
{
  "success": true,
  "data": [
    {
      "id": "<uuid>",
      "name": "بشري",
      "name_ar": "بشري",
      "subcategories": [
        { "id": "<uuid>", "name": "الأولى", "name_ar": "الأولى" },
        { "id": "<uuid>", "name": "الثانية", "name_ar": "الثانية" },
        { "id": "<uuid>", "name": "الثالثة", "name_ar": "الثالثة" },
        { "id": "<uuid>", "name": "الرابعة", "name_ar": "الرابعة" },
        { "id": "<uuid>", "name": "الخامسة", "name_ar": "الخامسة" },
        { "id": "<uuid>", "name": "السادسة", "name_ar": "السادسة" }
      ]
    }
  ]
}
```

Repeat the same **seven** top-level categories; each with the **same six** subcategories (each subcategory row may use a **different UUID per parent category**, or shared IDs — whatever your schema requires; the app only needs a unique `id` per selectable row).

---

## 4. Mobile implementation (reference)

- `lib/data/registration_categories_catalog.dart` — canonical names + filtering  
- `lib/services/courses_service.dart` — `getCategoriesForRegistration()`  
- `lib/screens/auth/register_screen.dart` — uses `getCategoriesForRegistration()`  

Other screens that call `getCategories()` unchanged unless you want the same filter globally.

---

*For backend handoff — 2026.*
