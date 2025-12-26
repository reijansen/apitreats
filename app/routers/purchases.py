from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Purchase, Product
from ..schemas import PurchaseCreate, PurchaseOut
from ..main import get_current_user
from ..websocket_manager import broadcast_new_purchase

router = APIRouter()

@router.post("/", response_model=PurchaseOut)
def create_purchase(purchase: PurchaseCreate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == purchase.product_id).first()
    if not product or not product.is_active:
        raise HTTPException(status_code=400, detail="Invalid product")
    if product.price is None:
        raise HTTPException(status_code=400, detail="Product price not set")
    total_amount = product.price * purchase.quantity
    db_purchase = Purchase(
        room_number=purchase.room_number,
        product_id=purchase.product_id,
        quantity=purchase.quantity,
        total_amount=total_amount
    )
    # Optionally decrement stock: product.current_stock -= purchase.quantity
    db.add(db_purchase)
    db.commit()
    db.refresh(db_purchase)
    broadcast_new_purchase({
        "id": db_purchase.id,
        "room_number": db_purchase.room_number,
        "product_name": product.name,
        "quantity": db_purchase.quantity,
        "total_amount": float(db_purchase.total_amount),
        "created_at": db_purchase.created_at.isoformat()
    })
    return PurchaseOut(
        id=db_purchase.id,
        room_number=db_purchase.room_number,
        product_name=product.name,
        quantity=db_purchase.quantity,
        total_amount=db_purchase.total_amount,
        created_at=db_purchase.created_at
    )

@router.get("/", response_model=list[PurchaseOut], dependencies=[Depends(get_current_user)])
def get_purchases(date: str = None, room_number: str = None, db: Session = Depends(get_db)):
    query = db.query(Purchase).join(Product)
    if date:
        query = query.filter(Purchase.created_at >= date, Purchase.created_at < date + " 23:59:59")
    if room_number:
        query = query.filter(Purchase.room_number == room_number)
    purchases = query.all()
    return [
        PurchaseOut(
            id=p.id,
            room_number=p.room_number,
            product_name=p.product.name,
            quantity=p.quantity,
            total_amount=p.total_amount,
            created_at=p.created_at
        ) for p in purchases
    ]