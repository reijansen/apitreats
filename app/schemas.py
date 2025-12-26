from pydantic import BaseModel, Field
from typing import Optional
from decimal import Decimal
from datetime import datetime

class ProductBase(BaseModel):
    name: str
    category: str
    price: Optional[Decimal] = None
    current_stock: int = 0
    is_active: bool = True

class ProductCreate(ProductBase):
    pass

class ProductUpdate(ProductBase):
    pass

class ProductStockUpdate(BaseModel):
    delta: Optional[int] = None
    current_stock: Optional[int] = None

class ProductOut(BaseModel):
    id: int
    name: str
    category: str
    price: Optional[Decimal]
    current_stock: int
    is_active: bool

class PurchaseCreate(BaseModel):
    room_number: str = Field(..., min_length=1)
    product_id: int
    quantity: int = Field(..., gt=0)

class PurchaseOut(BaseModel):
    id: int
    room_number: str
    product_name: str
    quantity: int
    total_amount: Decimal
    created_at: datetime

class UserCreate(BaseModel):
    email: str
    password: str
    role: str = "officer"

class UserOut(BaseModel):
    id: int
    email: str
    role: str

class LoginRequest(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str