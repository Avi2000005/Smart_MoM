const mongoose = require('mongoose');


async function ConnectDB() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');
  } catch(error){
    console.log('Error connecting to MongoDB:', error);
  }
}

module.exports = ConnectDB;