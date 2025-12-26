from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Product
from ..schemas import ProductCreate, ProductUpdate, ProductStockUpdate, ProductOut
from ..main import get_current_user
from ..websocket_manager import broadcast_stock_update

router = APIRouter()

@router.get("/", response_model=list[ProductOut])
def get_products(db: Session = Depends(get_db)):
    return db.query(Product).filter(Product.is_active == True).all()

@router.post("/", response_model=ProductOut, dependencies=[Depends(get_current_user)])
def create_product(product: ProductCreate, db: Session = Depends(get_db)):
    db_product = Product(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.put("/{product_id}", response_model=ProductOut, dependencies=[Depends(get_current_user)])
def update_product(product_id: int, product: ProductUpdate, db: Session = Depends(get_db)):
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    for key, value in product.dict().items():
        setattr(db_product, key, value)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.put("/{product_id}/stock", response_model=ProductOut, dependencies=[Depends(get_current_user)])
def update_stock(product_id: int, stock_update: ProductStockUpdate, db: Session = Depends(get_db)):
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    if stock_update.delta is not None:
        db_product.current_stock += stock_update.delta
    elif stock_update.current_stock is not None:
        db_product.current_stock = stock_update.current_stock
    db.commit()
    db.refresh(db_product)
    broadcast_stock_update({"product_id": db_product.id, "product_name": db_product.name, "current_stock": db_product.current_stock})
    return db_product