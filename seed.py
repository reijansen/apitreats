from app.database import SessionLocal, engine, Base
from app.models import Product

Base.metadata.create_all(bind=engine)

def seed_products():
    db = SessionLocal()
    if db.query(Product).count() > 0:
        print("Products already seeded.")
        return

    products = [
        # Hygiene
        {"name": "Safeguard", "category": "Hygiene", "price": 30.00, "current_stock": 0, "is_active": True},
        {"name": "Sister's Pad", "category": "Hygiene", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Charmee Pad", "category": "Hygiene", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Head & Shoulders", "category": "Hygiene", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Colgate", "category": "Hygiene", "price": 5.00, "current_stock": 0, "is_active": True},
        # Foods
        {"name": "Nissin Cup Seafood", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Sotanghon", "category": "Foods", "price": 28.00, "current_stock": 0, "is_active": True},
        {"name": "LM Chicken", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "LM Jjampong", "category": "Foods", "price": 30.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Spicy", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Hot Creamy Seafood", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Beef", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Bulalo", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Nissin Cup Batchoy", "category": "Foods", "price": 25.00, "current_stock": 0, "is_active": True},
        {"name": "Dewberry", "category": "Foods", "price": 10.00, "current_stock": 0, "is_active": True},
        {"name": "Quake Overload", "category": "Foods", "price": 10.00, "current_stock": 0, "is_active": True},
        {"name": "Milo", "category": "Foods", "price": 12.00, "current_stock": 0, "is_active": True},
        {"name": "Polvoron", "category": "Foods", "price": 2.00, "current_stock": 0, "is_active": True},
        {"name": "Fita", "category": "Foods", "price": 10.00, "current_stock": 0, "is_active": True},
        {"name": "Whatta Tops", "category": "Foods", "price": 10.00, "current_stock": 0, "is_active": True},
        {"name": "Pier 28", "category": "Foods", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Piattos", "category": "Foods", "price": 18.00, "current_stock": 0, "is_active": True},
        {"name": "Mang Juan", "category": "Foods", "price": None, "current_stock": 0, "is_active": False},  # Price unknown, inactive
        {"name": "Kopiko Blanca", "category": "Foods", "price": 10.00, "current_stock": 0, "is_active": True},
        {"name": "Oishi", "category": "Foods", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Marty's", "category": "Foods", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Pillows", "category": "Foods", "price": 12.00, "current_stock": 0, "is_active": True},
        {"name": "Patata", "category": "Foods", "price": 8.00, "current_stock": 0, "is_active": True},
        {"name": "Superstix", "category": "Foods", "price": 2.00, "current_stock": 0, "is_active": True},
        # Drinks
        {"name": "Coke & Sprite Sakto", "category": "Drinks", "price": 15.00, "current_stock": 0, "is_active": True},
    ]

    for product_data in products:
        product = Product(**product_data)
        db.add(product)
    db.commit()
    print("Products seeded successfully.")

if __name__ == "__main__":
    seed_products()