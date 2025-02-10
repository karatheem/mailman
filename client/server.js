// Declare all dependencies

const express = require('express');
const multer = require('multer');
const path = require('path');

// Create express app
const app = express();

// Multer config for file upload

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); //dir where files will be uploaded
    },
    filename: function (req, file, cb) {
        cb(null, 'index.html') //for now always save files as index.html, though this should be changed later
    }
});

const upload = multer({ storage: storage });

// Serve static content
app.use(express.static('public'));

// File upload route
app.post('/upload', upload.single('htmlFile'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('Please select and upload a file.');
    }
    res.send("Upload succesful!");
    });

// Server initialization

const PORT = 8080;
app.listen(PORT, () => {
    console.log('Server successfully started on port ${PORT}'); // Not sure why this is not working. Port printing isn't catching the variable. 
});
