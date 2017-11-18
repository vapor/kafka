enum APIKey: Int16, Encodable {
    case produce = 0
    case fetch = 1
    case listOffsets = 2
    case metadata = 3
    case leaderAndIsr = 4
    case stopReplica = 5
    case updateMetadata = 6
    case controlledShutdown = 7
    case offsetCommit = 8
    case offsetFetch = 9
    case findCoordinator = 10
    case joinGroup = 11
    case heartbeat = 12
    case leaveGroup = 13
    case syncGroup = 14
    case describeGroups = 15
    case listGroups = 16
    case saslHandshake = 17
    case apiVersions = 18
    case createTopics = 19
    case deleteTopics = 20
    case deleteRecords = 21
    case initProducerId = 22
    case offsetForLeaderEpoch = 23
    case addPatitionsToTxn = 24
    case addOffsetsToTxn = 25
    case endTxn = 26
    case writeTxnMarkers = 27
    case txnOffsetcommit = 28
    case describeAcls = 29
    case createAcls = 30
    case deleteAcls = 31
    case describeConfigs = 32
    case alterConfigs = 33
    case alterReplicaLogDirs = 34
    case describeLogDirs = 35
    case saslAuthenticate = 36
    case createPartitions = 37
}