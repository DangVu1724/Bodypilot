import pandas as pd
import os
import json
import urllib.request
import urllib.parse
import time
import concurrent.futures
from threading import Lock

# Paths
foods_src = r"c:\Personal\DATN\BodyPilot\data\opennutrition_foods_filtered.csv"
servings_src = r"c:\Personal\DATN\BodyPilot\data\opennutrition_food_servings_filtered.csv"

foods_dest = r"c:\Personal\DATN\BodyPilot\data\opennutrition_foods_translated.csv"
servings_dest = r"c:\Personal\DATN\BodyPilot\data\opennutrition_food_servings_translated.csv"
cache_path = r"c:\Personal\DATN\BodyPilot\data\translation_cache.json"

# Lock for thread-safe cache writing
cache_lock = Lock()

# Dictionary mapping for common food terms in names
food_dict = [
    # Multi-word phrases (longest first to prevent partial matches)
    ("boneless skinless", "không xương không da"),
    ("boneless", "không xương"),
    ("skinless", "không da"),
    ("chicken breast", "ức gà"),
    ("chicken thighs", "đùi gà"),
    ("chicken wings", "cánh gà"),
    ("ground beef", "thịt bò băm"),
    ("ground pork", "thịt heo băm"),
    ("ground chicken", "thịt gà băm"),
    ("whole milk", "sữa nguyên chất"),
    ("skim milk", "sữa tách béo"),
    ("coconut milk", "nước cốt dừa"),
    ("soy milk", "sữa đậu nành"),
    ("almond milk", "sữa hạnh nhân"),
    ("egg whites", "lòng trắng trứng"),
    ("egg yolks", "lòng đỏ trứng"),
    ("large eggs", "trứng lớn"),
    ("large egg", "trứng lớn"),
    ("boiled eggs", "trứng luộc"),
    ("hard-boiled eggs", "trứng luộc chín"),
    ("scrambled eggs", "trứng khuấy"),
    ("fried chicken", "gà rán"),
    ("roasted chicken", "gà quay"),
    ("grilled chicken", "gà nướng"),
    ("cooked rice", "cơm"),
    ("white rice", "gạo trắng"),
    ("brown rice", "gạo lứt"),
    ("jasmine rice", "gạo lài"),
    ("wild rice", "gạo hoang dã"),
    ("canned tuna", "cá ngừ đóng hộp"),
    ("canned salmon", "cá hồi đóng hộp"),
    ("frozen vegetables", "rau củ đông lạnh"),
    ("fresh vegetables", "rau củ tươi"),
    ("organic apple", "táo hữu cơ"),
    ("greek yogurt", "sữa chua hy lạp"),
    ("sweet potato", "khoai lang"),
    ("french fries", "khoai tây chiên"),
    ("potato chips", "khoai tây chiên lát"),
    ("tortilla chips", "bánh tortilla"),
    ("trail mix", "hạt và trái cây sấy"),
    ("pretzel chips", "bánh pretzels"),
    ("olive oil", "dầu ô liu"),
    ("coconut oil", "dầu dừa"),
    ("vegetable oil", "dầu thực vật"),
    ("canola oil", "dầu hạt cải"),
    ("sunflower oil", "dầu hướng dương"),
    ("sesame oil", "dầu mè"),
    ("soybean oil", "dầu đậu nành"),
    ("garlic powder", "bột tỏi"),
    ("onion powder", "bột hành"),
    ("cocoa powder", "bột ca cao"),
    ("chili powder", "bột ớt"),
    ("black pepper", "tiêu đen"),
    ("table salt", "muối ăn"),
    ("sea salt", "muối biển"),
    ("brown sugar", "đường nâu"),
    ("white sugar", "đường trắng"),
    ("cane sugar", "đường mía"),
    ("maple syrup", "si rô phong"),
    ("pancake syrup", "si rô bánh kếp"),
    ("chocolate milk", "sữa sô cô la"),
    ("strawberry milk", "sữa dâu"),
    ("vanilla milk", "sữa vani"),
    ("nonfat milk", "sữa tách béo"),
    ("lowfat milk", "sữa ít béo"),
    ("vegetable soup", "súp rau củ"),
    ("chicken soup", "súp gà"),
    ("beef soup", "súp bò"),
    ("tomato sauce", "sốt cà chua"),
    ("marinara sauce", "sốt marinara"),
    ("peanut sauce", "sốt đậu phộng"),
    ("alfredo sauce", "sốt alfredo"),
    ("hot sauce", "sốt cay"),
    ("chili sauce", "sốt ớt"),
    ("pesto sauce", "sốt pesto"),
    ("salad dressing", "sốt trộn salad"),
    ("honey mustard", "sốt mù tạt mật ong"),
    ("ranch dressing", "sốt ranch"),
    ("caesar salad", "salad caesar"),
    ("potato salad", "salad khoai tây"),
    ("tuna salad", "salad cá ngừ"),
    ("chicken salad", "salad gà"),
    ("fruit salad", "salad trái cây"),
    ("vanilla ice cream", "kem vani"),
    ("chocolate ice cream", "kem sô cô la"),
    ("strawberry ice cream", "kem dâu"),
    ("cheddar cheese", "phô mai cheddar"),
    ("mozzarella cheese", "phô mai mozzarella"),
    ("parmesan cheese", "phô mai parmesan"),
    ("feta cheese", "phô mai feta"),
    ("cream cheese", "kem phô mai"),
    ("swiss cheese", "phô mai thụy sĩ"),
    ("blue cheese", "phô mai xanh"),
    ("cottage cheese", "phô mai cottage"),
    ("ricotta cheese", "phô mai ricotta"),
    ("gouda cheese", "phô mai gouda"),
    ("monterey jack", "phô mai monterey jack"),
    ("provolone cheese", "phô mai provolone"),
    ("colby jack", "phô mai colby jack"),
    ("american cheese", "phô mai mỹ"),
    ("peanut butter", "bơ đậu phộng"),
    ("almond butter", "bơ hạnh nhân"),
    ("cashew butter", "bơ hạt điều"),
    ("sunflower butter", "bơ hướng dương"),
    ("chocolate chip cookie", "bánh quy sô cô la chip"),
    ("oatmeal cookie", "bánh quy yến mạch"),
    ("sugar cookie", "bánh quy đường"),
    ("blueberry muffin", "bánh muffin việt quất"),
    ("whole wheat bread", "bánh mì nguyên cám"),
    ("white bread", "bánh mì trắng"),
    ("wheat bread", "bánh mì lúa mì"),
    ("sourdough bread", "bánh mì chua"),
    ("rye bread", "bánh mì lúa mạch đen"),
    ("flatbread", "bánh mì dẹt"),
    ("pita bread", "bánh mì pita"),
    ("french baguette", "bánh mì baguette pháp"),
    ("corn tortilla", "bánh tortilla ngô"),
    ("flour tortilla", "bánh tortilla bột mì"),
    ("taco shell", "vỏ bánh taco"),
    ("quick oats", "yến mạch ăn liền"),
    ("rolled oats", "yến mạch cán dẹt"),
    ("steel cut oats", "yến mạch cắt thép"),
    ("sweet corn", "ngô ngọt"),
    ("popcorn", "bắp rang bơ"),
    ("green peas", "đậu hà lan"),
    ("black beans", "đậu đen"),
    ("kidney beans", "đậu thận"),
    ("pinto beans", "đậu pinto"),
    ("chickpeas", "đậu gà"),
    ("lentils", "đậu lăng"),
    ("soybeans", "đậu nành"),
    ("tofu", "đậu hũ"),
    ("tempeh", "tempeh"),
    ("miso", "tương miso"),
    ("edamame", "đậu nành nhật"),
    ("hummus", "sốt hummus"),
    ("falafel", "chả falafel"),
    ("tom yum", "canh tom yum"),
    ("butter chicken", "gà sốt bơ"),
    ("tandoori chicken", "gà nướng tandoori"),
    ("naan bread", "bánh mì naan"),
    ("biryani", "cơm biryani"),
    ("samosa", "bánh samosa"),
    ("strawberry", "dâu tây"),
    ("blueberry", "việt quất"),
    ("raspberry", "phúc bồn tử"),
    ("blackberry", "mâm xôi đen"),
    ("passion fruit", "chanh dây"),
    ("watermelon", "dưa hấu"),
    ("honeydew", "dưa hoàng kim"),
    ("avocado", "bơ"),
    ("coconut", "dừa"),
    ("lemon", "chanh vàng"),
    ("lime", "chanh xanh"),
    ("grapefruit", "bưởi"),
    ("pomegranate", "lựu"),
    ("cranberry", "nam việt quất"),
    ("papaya", "đu đủ"),
    ("apricot", "mơ tây"),
    ("bell pepper", "ớt chuông"),
    ("chili pepper", "ớt"),
    ("eggplant", "cà tím"),
    ("pumpkin", "bí đỏ"),
    ("radish", "củ cải"),
    ("lemongrass", "sả"),
    ("cilantro", "ngò rí"),
    ("parsley", "ngò tây"),
    ("basil", "húng quế"),
    ("mint", "bạc hà"),
    ("oregano", "kinh giới"),
    ("rosemary", "hương thảo"),
    ("thyme", "cỏ xạ hương"),
    ("sausage", "xúc xích"),
    ("bacon", "thịt ba rọi xông khói"),
    ("ham", "giăm bông"),
    ("meatball", "thịt viên"),
    ("steak", "bít tết"),
    ("seafood", "hải sản"),
    ("shrimp", "tôm"),
    ("crab", "cua"),
    ("lobster", "tôm hùm"),
    ("oyster", "hàu"),
    ("squid", "mực"),
    ("octopus", "bạch tuộc"),
    ("scallop", "sò điệp"),
    ("clams", "nghêu"),
    ("mussels", "vẹm"),
    # Single words
    ("raw", "sống"),
    ("cooked", "đã nấu"),
    ("fried", "chiên"),
    ("baked", "nướng"),
    ("steamed", "hấp"),
    ("boiled", "luộc"),
    ("roasted", "quay"),
    ("grilled", "nướng vỉ"),
    ("chicken", "gà"),
    ("beef", "bò"),
    ("pork", "heo"),
    ("lamb", "cừu"),
    ("duck", "vịt"),
    ("egg", "trứng"),
    ("rice", "gạo/cơm"),
    ("milk", "sữa"),
    ("apple", "táo"),
    ("banana", "chuối"),
    ("orange", "cam"),
    ("water", "nước"),
    ("juice", "nước ép"),
    ("salad", "sa lát"),
    ("soup", "súp"),
    ("potato", "khoai tây"),
    ("tomato", "cà chua"),
    ("onion", "hành tây"),
    ("garlic", "tỏi"),
    ("cheese", "phô mai"),
    ("butter", "bơ"),
    ("yogurt", "sữa chua"),
    ("bread", "bánh mì"),
    ("pasta", "mì"),
    ("noodles", "mì/bún"),
    ("salmon", "cá hồi"),
    ("tuna", "cá ngừ"),
    ("oil", "dầu"),
    ("salt", "muối"),
    ("sugar", "đường"),
    ("pepper", "tiêu"),
    ("sweet", "ngọt"),
    ("spicy", "cay"),
    ("organic", "hữu cơ"),
    ("fresh", "tươi"),
    ("canned", "đóng hộp"),
    ("dry", "khô"),
    ("dried", "sấy khô"),
    ("frozen", "đông lạnh"),
    ("whole", "nguyên"),
    ("low fat", "ít béo"),
    ("nonfat", "không béo"),
    ("unsweetened", "không đường"),
    ("sweetened", "có đường"),
    ("protein", "đạm"),
    ("bar", "thanh"),
    ("cookie", "bánh quy"),
    ("cake", "bánh ngọt"),
    ("cereal", "ngũ cốc"),
    ("chocolate", "sô cô la"),
    ("cream", "kem"),
    ("sauce", "sốt"),
    ("stew", "hầm"),
    ("curry", "cà ri"),
    ("pizza", "pizza"),
    ("burger", "hambơgơ"),
    ("sandwich", "bánh mì kẹp"),
    ("sushi", "sushi"),
    ("kimbap", "kimbap"),
    ("dumpling", "sủi cảo"),
    ("wonton", "hoành thánh"),
    ("coffee", "cà phê"),
    ("tea", "trà"),
    ("soda", "nước ngọt"),
    ("lemon", "chanh vàng"),
    ("lime", "chanh"),
    ("grape", "nho"),
    ("peach", "đào"),
    ("pear", "lê"),
    ("mango", "xoài"),
    ("pineapple", "dứa"),
    ("cherry", "anh đào"),
    ("avocado", "bơ"),
    ("peanut", "đậu phộng"),
    ("almond", "hạnh nhân"),
    ("cashew", "hạt điều"),
    ("walnut", "óc chó"),
    ("hazelnut", "hạt dẻ"),
    ("flour", "bột mì"),
    ("powder", "bột"),
    ("extract", "chiết xuất"),
    ("vinegar", "giấm"),
    ("mustard", "mù tạt"),
    ("mayonnaise", "mayonnaise"),
    ("ketchup", "tương cà"),
    ("syrup", "si rô"),
    ("jelly", "thạch"),
    ("jam", "mứt"),
    ("honey", "mật ong"),
    ("slice", "lát"),
    ("piece", "miếng"),
    ("cup", "cốc"),
    ("can", "lon"),
    ("bottle", "chai"),
    ("package", "gói"),
    ("bowl", "bát"),
    ("box", "hộp"),
    ("bag", "túi"),
    ("container", "hộp nhựa"),
    ("serving", "khẩu phần")
]

def translate_name_locally(name):
    if not isinstance(name, str):
        return name
    res = name.strip()
    # Replace phrases case-insensitively
    for eng, vie in food_dict:
        # Create case-insensitive regex for the word/phrase
        import re
        pattern = re.compile(re.escape(eng), re.IGNORECASE)
        res = pattern.sub(vie, res)
    # Capitalize first letter
    if len(res) > 0:
        res = res[0].upper() + res[1:]
    return res

def translate_text_web(text_list):
    joined_text = "\n".join([t.replace("\n", " ") for t in text_list])
    url = "https://translate.googleapis.com/translate_a/single"
    params = {
        "client": "gtx",
        "sl": "en",
        "tl": "vi",
        "dt": "t",
        "q": joined_text
    }
    
    full_url = url + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(
        full_url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    )
    
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req) as response:
                res = response.read().decode('utf-8')
                res_json = json.loads(res)
                translated_joined = ""
                for sentence in res_json[0]:
                    if sentence[0]:
                        translated_joined += sentence[0]
                
                # Split back by newline
                translated_list = translated_joined.split("\n")
                translated_list = [t.strip() for t in translated_list if t.strip() != ""]
                
                # If length matches, return
                if len(translated_list) == len(text_list):
                    return translated_list
                else:
                    # If lengths don't match, fallback to translating line-by-line in this attempt
                    print(f"Warning: Batch split length mismatch ({len(translated_list)} vs {len(text_list)}). Falling back to individual translation.")
                    individual_results = []
                    for single_text in text_list:
                        single_res = translate_text_web([single_text])
                        if single_res:
                            individual_results.append(single_res[0])
                        else:
                            individual_results.append(single_text)
                    return individual_results
        except Exception as e:
            print(f"Web Translation error (attempt {attempt + 1}/5): {e}")
            time.sleep(2 * (attempt + 1))
    return None

def load_cache():
    if os.path.exists(cache_path):
        try:
            with open(cache_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_cache(cache):
    with cache_lock:
        with open(cache_path, 'w', encoding='utf-8') as f:
            json.dump(cache, f, ensure_ascii=False, indent=2)

def main():
    print("--- STARTING TRANSLATION PROCESS ---")
    
    # 1. Translate Descriptions
    print("Loading unique descriptions to translate...")
    df_foods = pd.read_csv(foods_src)
    
    # Extract unique custom descriptions
    unique_descs = df_foods['description'].dropna().unique()
    custom_descs = [d for d in unique_descs if not str(d).startswith("Thông tin dinh dưỡng của")]
    print(f"Total custom descriptions requiring translation: {len(custom_descs)}")
    
    cache = load_cache()
    print(f"Loaded {len(cache)} cached translations.")
    
    to_translate = [d for d in custom_descs if d not in cache]
    print(f"Remaining descriptions to translate: {len(to_translate)}")
    
    # Batch translation of descriptions
    batch_size = 15
    batches = [to_translate[i:i + batch_size] for i in range(0, len(to_translate), batch_size)]
    
    def process_batch(batch_idx, batch):
        # Translate
        results = translate_text_web(batch)
        if results:
            local_updates = {}
            for original, translated in zip(batch, results):
                local_updates[original] = translated
            return local_updates
        else:
            print(f"Failed to translate batch {batch_idx + 1}")
            return {}

    if len(batches) > 0:
        print(f"Translating in {len(batches)} batches of {batch_size}...")
        
        # Parallel execution with thread pool
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            future_to_batch = {executor.submit(process_batch, i, batch): i for i, batch in enumerate(batches)}
            
            completed_count = 0
            for future in concurrent.futures.as_completed(future_to_batch):
                batch_idx = future_to_batch[future]
                try:
                    local_updates = future.result()
                    if local_updates:
                        cache.update(local_updates)
                        
                        # Save cache every 10 batches to minimize disk writes but secure data
                        completed_count += 1
                        if completed_count % 10 == 0 or completed_count == len(batches):
                            save_cache(cache)
                            print(f"Progress: {completed_count}/{len(batches)} batches completed. Cache saved.")
                except Exception as exc:
                    print(f"Batch {batch_idx + 1} generated an exception: {exc}")
                    
        # Final save
        save_cache(cache)
        print("All custom descriptions translated and cached successfully!")
    else:
        print("No new descriptions needed translation.")
        
    # 2. Re-load cache to map values
    cache = load_cache()
    
    # 3. Process Foods CSV: Translate names locally & apply translated descriptions
    print("\nProcessing foods dataset...")
    # Read in chunks to write opennutrition_foods_translated.csv
    chunk_size = 50000
    first_chunk = True
    processed_count = 0
    
    for chunk in pd.read_csv(foods_src, chunksize=chunk_size, low_memory=False):
        # Translate names
        chunk['name'] = chunk['name'].apply(translate_name_locally)
        
        # Translate descriptions using cache
        def map_desc(desc):
            if pd.isna(desc):
                return desc
            desc_str = str(desc)
            if desc_str.startswith("Thông tin dinh dưỡng của"):
                # Clean prefix for default
                food_name_eng = desc_str.replace("Thông tin dinh dưỡng của ", "")
                food_name_vie = translate_name_locally(food_name_eng)
                return f"Thông tin dinh dưỡng của {food_name_vie}"
            
            # Custom description
            return cache.get(desc_str, desc_str)
            
        chunk['description'] = chunk['description'].apply(map_desc)
        
        # Save
        if first_chunk:
            chunk.to_csv(foods_dest, index=False, mode='w')
            first_chunk = False
        else:
            chunk.to_csv(foods_dest, index=False, mode='a', header=False)
            
        processed_count += len(chunk)
        print(f"Translated and saved {processed_count} foods...")
        
    print(f"Created translated foods CSV at {foods_dest}.")
    
    # 4. Process Servings CSV: Translate serving names
    print("\nProcessing servings dataset...")
    first_chunk = True
    processed_servings = 0
    for chunk in pd.read_csv(servings_src, chunksize=chunk_size, low_memory=False):
        # Translate serving name (e.g., "1 cup" -> "1 cốc")
        chunk['name'] = chunk['name'].apply(translate_name_locally)
        
        if first_chunk:
            chunk.to_csv(servings_dest, index=False, mode='w')
            first_chunk = False
        else:
            chunk.to_csv(servings_dest, index=False, mode='a', header=False)
            
        processed_servings += len(chunk)
        print(f"Translated and saved {processed_servings} servings...")
        
    print(f"Created translated servings CSV at {servings_dest}.")
    print("\n--- TRANSLATION COMPLETED SUCCESSFULLY! ---")

if __name__ == '__main__':
    main()
