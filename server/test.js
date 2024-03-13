const fs = require('fs');
const path = require('path');

const dataPath = path.join(__dirname, 'data.json');

// Helper function to read data from the JSON file
function readData() {
  const rawData = fs.readFileSync(dataPath);
  return JSON.parse(rawData);
}

// Helper function to write data to the JSON file
function writeData(data) {
  fs.writeFileSync(dataPath, JSON.stringify(data, null, 2));
}

// CREATE operation
function create(data) {
  const allData = readData();
  allData.push(data);
  writeData(allData);
}

// READ operation
function read() {
  return readData();
}

// UPDATE operation
function update(id, newData) {
  const allData = readData();
  const index = allData.findIndex((item) => item.id === id);
  if (index !== -1) {
    allData[index] = { ...allData[index], ...newData };
    writeData(allData);
    return true;
  }
  return false;
}

// DELETE operation
function remove(id) {
  const allData = readData();
  const updatedData = allData.filter((item) => item.id !== id);
  if (allData.length !== updatedData.length) {
    writeData(updatedData);
    return true;
  }
  return false;
}

// Test the CRUD operations
create({ id: 1, name: 'John Doe', age: 30 });
create({ id: 2, name: 'Jane Smith', age: 25 });

console.log('All data:', read());

// update(1, { age: 35 });
// console.log('All data after update:', read());

// remove(2);
// console.log('All data after delete:', read());
