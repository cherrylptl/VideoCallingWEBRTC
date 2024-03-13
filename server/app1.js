require("dotenv").config({ path: "./../.env" });
const express = require("express");
const app = express();
var mongoose = require("./db/index");
const server = require("http").createServer(app);
const expressSession = require("express-session");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const messageController = require("./services/message/src/controller/message.controller");
const { asyncHandler } = require("./utils/helpers/index");

app.use(cors());

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const logger = require("./Logger");
const session = expressSession;
var memoryStore = new session.MemoryStore();
app.use(
  session({
    secret: "some secret",
    resave: false,
    saveUninitialized: true,
    store: memoryStore,
  })
);
const PORT = process.env.MESSAGE_PORT || 6009;

app.get("/", (req, res) => {
  res.send("Server is up!");
});

var corsOptions = {
  origin: "http://localhost:3000",
  credentials: true,
  optionsSuccessStatus: 200, // For legacy browser support
};

require("./routes")(app);

server.listen(PORT, () => {
  logger.info(`Server running at http://localhost:${PORT}/ `);
  console.log(`Server running at http://localhost:${PORT}/`.blue);
});

const io = require("socket.io")(server, {
  cors: {
    origin: "*",
  },
});

const connectedUsers = [];
io.on("connection", async (socket) => {
  const id = socket.handshake.query.id;
  console.log("iddd->", id);
  socket.join(id);
  if (connectedUsers.indexOf(id) === -1) {
    connectedUsers.push(id);
  }
  socket.emit("connected-user", connectedUsers);
  io.emit("connected-user", connectedUsers);

  const userWiseCounter = await messageController.getUserMessageCounter();
  socket.emit("get-usercount", userWiseCounter);

  socket.on("read-message", async (data) => {
    const readRes = await messageController.readUsermessage(data);
    console.log("data-reauuud-------------->", readRes);

    if (readRes.acknowledged) {
      data["status"] = true;
    } else {
      data["status"] = false;
    }
    socket.emit("message-read", data);
    io.emit("message-read", data);

    const userWiseCounter = await messageController.getUserMessageCounter();
    socket.emit("get-usercount", userWiseCounter);
  });

  socket.on("send-message", async (data) => {
    console.log("data", data);
    const res = await messageController.createmessage(data);
    const userWiseCounter = await messageController.getUserMessageCounter();
    const getLastMessageUser = await messageController.getLastMessageUser(
      data.receiver.Id
    );
    const getLastMessageUsertosender =
      await messageController.getLastMessageUser(data.sender.Id);

    socket.emit("get-sorteduser", getLastMessageUsertosender); //to sender

    socket
      .to(data.receiver.Id)
      .emit("receive-message", data, userWiseCounter, getLastMessageUser); //to receiver
    socket.to(data.receiver.Id).emit("push-notification",data);
  
  });

  socket.on("typing", (data) => {
    if (data.typing == true)
      socket.to(data.receiver).emit("typing-display", data);
    else socket.to(data.receiver).emit("typing-display", data);
  });

  const getLastMessageUser = await messageController.getLastMessageUser(id);
  socket.emit("get-sorteduser", getLastMessageUser);

  // const getLastMessage = await messageController.getLastMessage(id);
  // socket.emit("get-lastmessageuserwise", getLastMessage);

  socket.on("disconnect", () => {
    console.log("user disconnected");
    const index = connectedUsers.indexOf(id);
    if (index > -1) {
      connectedUsers.splice(index, 1);
    }
    socket.emit("connected-user", connectedUsers);
    io.emit("connected-user", connectedUsers);
  });
});

module.exports = app;