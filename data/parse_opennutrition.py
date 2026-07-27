import pandas as pd
import uuid
import json
import os
import sys

# Paths
tsv_path = r"c:\Personal\DATN\BodyPilot\data\opennutrition_foods.tsv"
output_foods_csv = r"c:\Personal\DATN\BodyPilot\data\opennutrition_foods.csv"
output_servings_csv = r"c:\Personal\DATN\BodyPilot\data\opennutrition_food_servings.csv"

# Category UUIDs
category_mapping = {
    'DRY_DISH': '0852d9bc-2e45-4277-87e8-4e9497c6f0d4',
    'SEASONING': '179f9c83-d8b7-4ed3-852a-438529a88828',
    'SEAFOOD': '34d3024c-4bb7-46a0-8480-f45f99dd3d32',
    'HOME_MEALS': '41bc8080-6a03-46d4-9262-b0a40e7b2db3',
    'BREAKFASH': '59acc58d-5ea1-48bc-8855-308685235c14',
    'DAIRY': '5a495c98-b00c-4007-aeac-501f3ae8e030',
    'GRAIN': '7aa75582-4482-4305-80f6-aa6cfccec44c',
    'FAST_FOOD': '7b603b8f-7b09-4100-966b-31a4b3d6b932',
    'NOODLE_SOUP': '858156f4-0c43-40f6-b7d6-9d2f1d491e33',
    'BEVERAGE': '85ac50db-ec45-4d0f-b644-c46a43621f31',
    'DESSERT': '9d4dc1ac-566d-45dd-8f5c-976afae98cfc',
    'OILS': 'bef265e7-b8f4-4c9d-a8b3-c6c189ced1e8',
    'FRUIT': 'ce0eea03-f333-4ddb-b8a7-ce39efaf437a',
    'VEG': 'd955f552-54bb-4357-b9be-a0269615a707',
    'MEAT': 'de172d43-2578-4f27-a571-6d871460d273'
}

def guess_category(name):
    name_lower = name.lower()
    
    # 1. Seasoning / Spices
    if any(k in name_lower for k in ['salt', 'vinegar', 'pepper', 'spice', 'herb', 'garlic powder', 'onion powder', 'cinnamon', 'oregano', 'basil', 'thyme', 'rosemary', 'seasoning']):
        return category_mapping['SEASONING']
    # 2. Oils & Fats
    if any(k in name_lower for k in ['oil', 'butter', 'margarine', 'lard', 'tallow', 'ghee', 'fat']):
        return category_mapping['OILS']
    # 3. Beverages
    if any(k in name_lower for k in ['juice', 'tea', 'coffee', 'soda', 'beverage', 'drink', 'water', 'coke', 'beer', 'wine', 'alcohol']):
        return category_mapping['BEVERAGE']
    # 4. Dessert / Sweets
    if any(k in name_lower for k in ['cake', 'cookie', 'sweet', 'chocolate', 'pudding', 'candy', 'ice cream', 'dessert', 'donut', 'muffin', 'pastry']):
        return category_mapping['DESSERT']
    # 5. Fast Food
    if any(k in name_lower for k in ['pizza', 'burger', 'fries', 'nuggets', 'hot dog', 'cheeseburger']):
        return category_mapping['FAST_FOOD']
    # 6. Noodle Soup
    if any(k in name_lower for k in ['noodle soup', 'ramen', 'udon', 'pho', 'wonton soup', 'soup']):
        return category_mapping['NOODLE_SOUP']
    # 7. Seafood
    if any(k in name_lower for k in ['fish', 'shrimp', 'crab', 'lobster', 'salmon', 'tuna', 'cod', 'seafood', 'oyster', 'squid', 'octopus']):
        return category_mapping['SEAFOOD']
    # 8. Meat
    if any(k in name_lower for k in ['chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'meat', 'sausage', 'bacon', 'ham', 'steak']):
        return category_mapping['MEAT']
    # 9. Dairy (including eggs)
    if any(k in name_lower for k in ['milk', 'cheese', 'yogurt', 'whey', 'egg']):
        return category_mapping['DAIRY']
    # 10. Fruits
    if any(k in name_lower for k in ['apple', 'banana', 'orange', 'grape', 'strawberry', 'berry', 'peach', 'pear', 'mango', 'lemon', 'lime', 'fruit', 'pineapple', 'watermelon', 'cherry']):
        return category_mapping['FRUIT']
    # 11. Vegetables
    if any(k in name_lower for k in ['onion', 'garlic', 'tomato', 'potato', 'carrot', 'broccoli', 'spinach', 'kale', 'salad', 'vegetable', 'pepper', 'cabbage', 'cucumber', 'mushroom', 'lettuce']):
        return category_mapping['VEG']
    # 12. Grains / Carbs
    if any(k in name_lower for k in ['rice', 'oats', 'wheat', 'flour', 'bread', 'pasta', 'spaghetti', 'grain', 'corn', 'starch', 'barley', 'oatmeal', 'cereal']):
        return category_mapping['GRAIN']
        
    # Default fallback
    return category_mapping['GRAIN']


def determine_food_type(name, labels_str):
    name_lower = name.lower()
    
    # 1. Parse labels list
    lbls = []
    if pd.notna(labels_str) and str(labels_str).strip() != "":
        try:
            lbls = [l.lower() for l in json.loads(labels_str)]
        except Exception:
            pass
            
    # Strong ingredient labels
    if any(l in lbls for l in ['raw', 'fresh', 'dry', 'dried', 'unprepared']):
        return 'INGREDIENT'
        
    # Strong dish labels
    if any(l in lbls for l in ['cooked', 'baked', 'fried', 'grilled', 'roasted', 'prepared', 'restaurant', 'fast food']):
        return 'DISH'
        
    # 2. Check name keywords
    # Ingredient keywords
    ingredient_keywords = [
        'raw', 'fresh', 'dry', 'dried', 'unprepared', 'uncooked', 'unheated', 
        'flour', 'powder', 'starch', 'seed', 'kernel', 'yeast', 'extract',
        'oregano', 'basil', 'thyme', 'parsley', 'rosemary', 'spice', 'herb',
        'salt', 'vinegar', 'oil', 'lard', 'tallow', 'ghee', 'whey', 'crude',
        'whole grain', 'whole-wheat', 'raw meat', 'raw chicken', 'raw beef', 'raw pork',
        'egg, white, raw', 'egg, yolk, raw', 'egg, whole, raw', 'fluid, milk'
    ]
    if any(k in name_lower for k in ingredient_keywords):
        return 'INGREDIENT'
        
    # Dish keywords
    dish_keywords = [
        'cooked', 'baked', 'fried', 'grilled', 'roasted', 'steamed', 'boiled', 
        'stewed', 'sautéed', 'pan-fried', 'broiled', 'poached', 'scrambled',
        'soup', 'stew', 'curry', 'sauce', 'gravy', 'salad', 'sandwich', 'burger',
        'pizza', 'pasta', 'lasagna', 'spaghetti', 'macaroni', 'noodle', 'casserole',
        'pie', 'cake', 'cookie', 'bread', 'bun', 'bagel', 'pancake', 'waffle',
        'dimsum', 'sushi', 'kimbap', 'taco', 'burrito', 'quesadilla', 'enchilada',
        'hummus', 'dip', 'salsa', 'pudding', 'custard', 'yogurt', 'smoothie',
        'prepared', 'ready-to-serve', 'ready to eat', 'instant', 'restaurant', 'fast food'
    ]
    if any(k in name_lower for k in dish_keywords):
        return 'DISH'
        
    # 3. Fallback based on category keywords
    # If it contains meat/fish/shellfish and doesn't mention cooked, it's raw meat -> INGREDIENT
    raw_meats = ['chicken', 'beef', 'pork', 'turkey', 'lamb', 'duck', 'shrimp', 'salmon', 'tuna', 'cod', 'fish', 'lobster', 'crab']
    if any(m in name_lower for m in raw_meats) and not any(k in name_lower for k in ['cooked', 'fried', 'grilled', 'roasted', 'canned', 'smoked']):
        return 'INGREDIENT'
        
    # If it's vegetables or fruits -> usually logged raw (INGREDIENT)
    vegetables_fruits = ['broccoli', 'carrot', 'spinach', 'kale', 'lettuce', 'cucumber', 'cabbage', 'onion', 'garlic', 'potato', 'apple', 'banana', 'orange', 'grape', 'strawberry', 'peach', 'pear', 'mango', 'blueberry']
    if any(v in name_lower for v in vegetables_fruits) and not any(k in name_lower for k in ['cooked', 'fried', 'baked', 'canned']):
        return 'INGREDIENT'
        
    # Fallback for simple grains and milk
    if any(k in name_lower for k in ['milk', 'butter', 'oats', 'rice', 'barley', 'wheat', 'rye']):
        if not any(k in name_lower for k in ['cooked', 'fried', 'baked']):
            return 'INGREDIENT'
            
    # Default to DISH for complex composite items
    return 'DISH'

def make_uuid(item_id, prefix="opennutrition"):
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{prefix}-{item_id}"))

# Process TSV in chunks to save memory
chunk_size = 10000
foods_count = 0
servings_count = 0
ingredient_count = 0
dish_count = 0

# Check file existence
if not os.path.exists(tsv_path):
    print(f"Error: {tsv_path} not found.")
    sys.exit(1)

print("Starting to parse opennutrition_foods.tsv with smart type classification...")

# Open CSV writers
first_chunk = True

for chunk in pd.read_csv(tsv_path, sep='\t', chunksize=chunk_size, low_memory=False):
    foods_chunk = []
    servings_chunk = []
    
    for _, row in chunk.iterrows():
        item_id = row['id']
        name = row['name']
        description = row.get('description', '')
        labels = row.get('labels', '')
        
        # Skip if name is null
        if pd.isna(name) or str(name).strip() == "":
            continue
            
        # Parse nutrition
        nut_str = row.get('nutrition_100g', '{}')
        nut_data = {}
        if pd.notna(nut_str) and str(nut_str).strip() != "":
            try:
                nut_data = json.loads(nut_str)
            except Exception:
                pass
                
        # Parse serving
        serv_str = row.get('serving', '{}')
        serv_data = {}
        if pd.notna(serv_str) and str(serv_str).strip() != "":
            try:
                serv_data = json.loads(serv_str)
            except Exception:
                pass
                
        # Generate IDs
        food_uuid = make_uuid(item_id, "food")
        default_serving_uuid = make_uuid(item_id, "serving-100g")
        
        # Map values
        calories = nut_data.get('calories')
        protein = nut_data.get('protein')
        fat = nut_data.get('total_fat')
        carbs = nut_data.get('carbohydrates')
        fiber = nut_data.get('dietary_fiber')
        sugar = nut_data.get('total_sugars')
        sodium = nut_data.get('sodium')
        
        category_id = guess_category(name)
        food_type = determine_food_type(name, labels)
        
        if food_type == 'INGREDIENT':
            ingredient_count += 1
        else:
            dish_count += 1
        
        # Health score logic: default based on category
        health_score = 75
        if category_id == category_mapping['VEG']:
            health_score = 95
        elif category_id == category_mapping['FRUIT']:
            health_score = 90
        elif category_id == category_mapping['SEAFOOD']:
            health_score = 88
        elif category_id == category_mapping['MEAT']:
            health_score = 80
            
        # Append to foods chunk
        foods_chunk.append({
            'id': food_uuid,
            'created_at': None,
            'updated_at': None,
            'name': name,
            'type': food_type,
            'calories_per_100g': round(float(calories), 2) if calories is not None else None,
            'protein_per_100g': round(float(protein), 2) if protein is not None else None,
            'fat_per_100g': round(float(fat), 2) if fat is not None else None,
            'carbs_per_100g': round(float(carbs), 2) if carbs is not None else None,
            'fiber_per_100g': round(float(fiber), 2) if fiber is not None else None,
            'sugar_per_100g': round(float(sugar), 2) if sugar is not None else None,
            'sodium_mg_per_100g': round(float(sodium), 2) if sodium is not None else None,
            'category_id': category_id,
            'default_serving_id': default_serving_uuid,
            'image_url': None,
            'description': description if pd.notna(description) and str(description).strip() != "" else f"Thông tin dinh dưỡng của {name}",
            'health_score': health_score
        })
        foods_count += 1
        
        # 100g Portion Serving
        servings_chunk.append({
            'id': default_serving_uuid,
            'created_at': None,
            'updated_at': None,
            'food_id': food_uuid,
            'name': '100g Portion',
            'unit_code': 'GRAM',
            'grams': 100.0
        })
        servings_count += 1
        
        # Check for custom servings in the serving JSON
        if serv_data:
            metric = serv_data.get('metric', {})
            common = serv_data.get('common', {})
            
            grams = metric.get('quantity')
            unit = common.get('unit')
            qty = common.get('quantity', 1)
            
            if grams and pd.notna(grams) and float(grams) > 0:
                p_name = ""
                if unit:
                    p_name = f"{qty} {unit}"
                else:
                    p_name = "Custom Portion"
                
                custom_serving_uuid = make_uuid(item_id, "serving-custom")
                servings_chunk.append({
                    'id': custom_serving_uuid,
                    'created_at': None,
                    'updated_at': None,
                    'food_id': food_uuid,
                    'name': p_name,
                    'unit_code': 'GRAM',
                    'grams': round(float(grams), 2)
                })
                servings_count += 1
                
    # Convert chunks to DataFrames
    foods_df_chunk = pd.DataFrame(foods_chunk)
    servings_df_chunk = pd.DataFrame(servings_chunk)
    
    # Save/Append to CSV
    if first_chunk:
        foods_df_chunk.to_csv(output_foods_csv, index=False, mode='w')
        servings_df_chunk.to_csv(output_servings_csv, index=False, mode='w')
        first_chunk = False
    else:
        foods_df_chunk.to_csv(output_foods_csv, index=False, mode='a', header=False)
        servings_df_chunk.to_csv(output_servings_csv, index=False, mode='a', header=False)
        
    print(f"Processed {foods_count} foods so far... ({ingredient_count} ingredients, {dish_count} dishes)")

print(f"\nParsing completed successfully!")
print(f"Total foods processed: {foods_count}")
print(f"Total ingredients: {ingredient_count}")
print(f"Total dishes: {dish_count}")
print(f"Total servings created: {servings_count}")
print(f"Output files saved to:\n - {output_foods_csv}\n - {output_servings_csv}")
