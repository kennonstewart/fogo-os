from fastapi import FastAPI
from api import endpoints
from magnum import Magnum

app = FastAPI()
handler = Magnum(app)
app.include_router(endpoints.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)