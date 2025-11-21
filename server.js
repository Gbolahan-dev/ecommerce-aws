const express = require('express');
const app = express();
const path = require('path');

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// The "Stateless" Database
const products = [
    { id: 1, name: "Cloud Kicks v1", price: 120, img: "https://images.unsplash.com/photo-1542291026-7eec264c27ff" },
    { id: 2, name: "DevOps Runners", price: 95, img: "https://images.unsplash.com/photo-1551107696-a4b0c5a0d9a2" },
    { id: 3, name: "Terraform Trekkers", price: 150, img: "https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa" },
    { id: 4, name: "Kubernetes Kicks", price: 110, img: "https://images.unsplash.com/photo-1560769629-975e13f0c470" }
];

app.get('/', (req, res) => {
    res.render('index', { products: products });
});

app.get('/health', (req, res) => {
    res.status(200).send('Healthy');
});

const PORT = 8080;
app.listen(PORT, () => {
    console.log(`Store running on port ${PORT}`);
});
