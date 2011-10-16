Debug = require('../../lib/debug')
EventEmitter = require('events').EventEmitter
MessageIO = require('../../lib/message-io')
Packet = require('../../lib/packet').Packet
require('buffertools')

class Connection extends EventEmitter
  setTimeout: ->

  connect: ->

  write: (data) ->
    packet = new Packet(data)
    @emit('packet', packet)

packetType = 2;

exports.sendSmallerThanOnePacket = (test) ->
  payload = new Buffer([1, 2, 3])

  connection = new Connection()
  connection.on('packet', (packet) ->
    test.ok(packet.last())
    test.strictEqual(packet.type(), packetType)
    test.ok(packet.data().equals(payload))

    test.done()
  )

  io = new MessageIO(connection, 0, new Debug())
  io.packetSize(4)
  io.sendMessage(packetType, payload)

exports.sendExactlyPacket = (test) ->
  payload = new Buffer([1, 2, 3, 4])

  connection = new Connection()
  connection.on('packet', (packet) ->
    test.ok(packet.last())
    test.strictEqual(packet.type(), packetType)
    test.ok(packet.data().equals(payload))

    test.done()
  )

  io = new MessageIO(connection, 0, new Debug())
  io.packetSize(4)
  io.sendMessage(packetType, payload)

exports.sendOneLongerThanPacket = (test) ->
  payload = new Buffer([1, 2, 3, 4, 5])
  packetNumber = 0

  connection = new Connection()
  connection.on('packet', (packet) ->
    packetNumber++

    test.strictEqual(packet.type(), packetType)

    switch packetNumber
      when 1
        test.ok(!packet.last())
        test.strictEqual(packet.packetId(), packetNumber - 1)
        test.ok(packet.data().equals(new Buffer([1, 2, 3, 4])))
      when 2
        test.ok(packet.last())
        test.strictEqual(packet.packetId(), packetNumber - 1)
        test.ok(packet.data().equals(new Buffer([5])))

        test.done()
  )

  io = new MessageIO(connection, 0, new Debug())
  io.packetSize(4)
  io.sendMessage(packetType, payload)

exports.receiveOnePacket = (test) ->
  payload = new Buffer([1, 2, 3])
  connection = new Connection()

  io = new MessageIO(connection, 0, new Debug())
  io.on('message', (messageType, messagePayload) ->
    test.strictEqual(messageType, packetType)
    test.ok(messagePayload.equals(payload))

    test.done()
  )

  packet = new Packet(packetType)
  packet.last(true)
  packet.addData(payload)
  connection.emit('data', packet.buffer)

exports.receiveOnePacketInTwoChunks = (test) ->
  payload = new Buffer([1, 2, 3])
  connection = new Connection()

  io = new MessageIO(connection, 0, new Debug())
  io.on('message', (messageType, messagePayload) ->
    test.strictEqual(messageType, packetType)
    test.ok(messagePayload.equals(payload))

    test.done()
  )

  packet = new Packet(packetType)
  packet.last(true)
  packet.addData(payload)
  connection.emit('data', packet.buffer.slice(0, 4))
  connection.emit('data', packet.buffer.slice(4))

exports.receiveTwoPackets = (test) ->
  payload = new Buffer([1, 2, 3])
  connection = new Connection()

  io = new MessageIO(connection, 0, new Debug())
  io.on('message', (messageType, messagePayload) ->
    test.strictEqual(messageType, packetType)
    test.ok(messagePayload.equals(payload))

    test.done()
  )

  packet = new Packet(packetType)
  packet.addData(payload.slice(0, 2))
  connection.emit('data', packet.buffer)

  packet = new Packet(packetType)
  packet.last(true)
  packet.addData(payload.slice(2, 3))
  connection.emit('data', packet.buffer)
