/// Model class representing ONU details extracted from the OLT's javascript array.
class OnuData {
  final String? oltId;
  final String id;
  final String name;
  final String macAddress;
  final String status;
  final String fwVersion;
  final String chipId;
  final String ports;
  final String ctcStatus;
  final String ctcVer;
  final String activate;
  final String rtt;
  final String distance;
  final String temperature;
  final String txPower;
  final String rxPower;
  final String onlineTime;
  final String offlineTime;
  final String offlineReason;
  final String uptime;
  final String deregisterCnt;
  final String firstUpTime;
  final String voltage;
  final String biasCurrent;

  OnuData({
    this.oltId,
    required this.id,
    required this.name,
    required this.macAddress,
    required this.status,
    required this.fwVersion,
    required this.chipId,
    required this.ports,
    required this.ctcStatus,
    required this.ctcVer,
    required this.activate,
    required this.rtt,
    required this.distance,
    required this.temperature,
    required this.txPower,
    required this.rxPower,
    required this.onlineTime,
    required this.offlineTime,
    required this.offlineReason,
    required this.uptime,
    required this.deregisterCnt,
    this.firstUpTime = "--",
    this.voltage = "--",
    this.biasCurrent = "--",
  });

  factory OnuData.fromRawList(List<String> raw) {
    String getValue(int idx) => idx < raw.length ? raw[idx] : "";

    final String id = getValue(0);
    final String name = getValue(1);
    final String macAddress = getValue(2);
    final String status = getValue(3);
    final String fwVersion = getValue(4);
    final String chipId = getValue(5);
    final String ports = getValue(6);
    final String ctcStatusRaw = getValue(7);
    final String ctcVer = getValue(8);
    final String activateRaw = getValue(9);
    final String rtt = getValue(10);
    final String temperature = getValue(11);
    final String txPower = getValue(14);
    final String rxPower = getValue(15);
    final String onlineTime = getValue(16);
    final String offlineTime = getValue(17);
    final String offlineReasonRaw = getValue(18);
    final String uptimeRaw = getValue(19);
    final String deregisterCnt = getValue(20);
    final String dyingGaspRaw = getValue(21);

    // ctc status mapping
    final ctcStatusList = [
      "--",
      "MpcpDiscovery",
      "MpcpSla",
      "CtcInfo",
      "RequestCfg",
      "CtcNegDone",
    ];
    int? ctcIdx = int.tryParse(ctcStatusRaw);
    final String ctcStatus =
        (ctcIdx != null && ctcIdx >= 0 && ctcIdx < ctcStatusList.length)
        ? ctcStatusList[ctcIdx]
        : ctcStatusRaw;

    // auth status mapping
    final String activate = activateRaw == '2' ? "Deactivate" : "Activate";

    // Distance calculation
    int? rttVal = int.tryParse(rtt);
    String distance = "--";
    if (rttVal != null) {
      double distVal = rttVal * 1.6393 - 157;
      distVal = distVal > 157 ? (distVal - 157) : 1;
      distance = distVal.toStringAsFixed(0);
    }

    // Offline Reason mapping
    final offReasonList = [
      "Other",
      "TIMEOUT",
      "ONU-init",
      "OLT-init",
      "RejectByBlackList",
      "RejectByWhiteList",
    ];
    String offlineReason = "";
    if (dyingGaspRaw == '1') {
      offlineReason = "Dying_gasp";
    } else {
      int? offIdx = int.tryParse(offlineReasonRaw);
      offlineReason =
          (offIdx != null && offIdx >= 0 && offIdx < offReasonList.length)
          ? offReasonList[offIdx]
          : offlineReasonRaw;
    }

    // Uptime formatting
    int? uptimeSec = int.tryParse(uptimeRaw);
    final String uptime = uptimeSec != null
        ? formatSecondsToUptime(uptimeSec)
        : "--";

    return OnuData(
      id: id,
      name: name,
      macAddress: macAddress,
      status: status,
      fwVersion: fwVersion,
      chipId: chipId,
      ports: ports,
      ctcStatus: ctcStatus,
      ctcVer: ctcVer,
      activate: activate,
      rtt: rtt,
      distance: distance,
      temperature: temperature,
      txPower: txPower,
      rxPower: rxPower,
      onlineTime: onlineTime,
      offlineTime: offlineTime,
      offlineReason: offlineReason,
      uptime: uptime,
      deregisterCnt: deregisterCnt,
    );
  }

  OnuData mergeWithConfig({
    required List<String> infoRaw,
    required List<String> opmRaw,
  }) {
    String getVal(List<String> list, int idx) =>
        idx < list.length ? list[idx] : "";

    final String configName = getVal(infoRaw, 1);
    final String configStatus = getVal(infoRaw, 3);
    final String configFw = getVal(infoRaw, 4);
    final String configChip = getVal(infoRaw, 5);
    final String configPorts = getVal(infoRaw, 6);
    final String firstUp = getVal(infoRaw, 7);
    final String lastUp = getVal(infoRaw, 8);
    final String lastOff = getVal(infoRaw, 9);
    final String ctcStatusRaw = getVal(infoRaw, 10);
    final String ctcVerRaw = getVal(infoRaw, 11);
    final String activateRaw = getVal(infoRaw, 12);
    final String offlineReasonRaw = getVal(infoRaw, 13);
    final String uptimeRaw = getVal(infoRaw, 14);
    final String deregisterRaw = getVal(infoRaw, 15);
    final String dyingGaspRaw = getVal(infoRaw, 16);

    // ctc status mapping
    final ctcStatusList = [
      "--",
      "MpcpDiscovery",
      "MpcpSla",
      "CtcInfo",
      "RequestCfg",
      "CtcNegDone",
    ];
    int? ctcIdx = int.tryParse(ctcStatusRaw);
    final String ctcStatus =
        (ctcIdx != null && ctcIdx >= 0 && ctcIdx < ctcStatusList.length)
        ? ctcStatusList[ctcIdx]
        : ctcStatusRaw;

    // auth status mapping
    final String activate = activateRaw == '2' ? "Deactivate" : "Activate";

    // Offline Reason mapping
    final offReasonList = [
      "Other",
      "TIMEOUT",
      "ONU-init",
      "OLT-init",
      "RejectByBlackList",
      "RejectByWhiteList",
    ];
    String offlineReason = "";
    if (dyingGaspRaw == '1') {
      offlineReason = "Dying_gasp";
    } else {
      int? offIdx = int.tryParse(offlineReasonRaw);
      offlineReason =
          (offIdx != null && offIdx >= 0 && offIdx < offReasonList.length)
          ? offReasonList[offIdx]
          : offlineReasonRaw;
    }

    // Uptime formatting
    int? uptimeSec = int.tryParse(uptimeRaw);
    final String uptime = uptimeSec != null
        ? formatSecondsToUptime(uptimeSec)
        : "--";

    // Opm parameters
    final String tempVal = getVal(opmRaw, 1);
    final String voltVal = getVal(opmRaw, 2);
    final String biasVal = getVal(opmRaw, 3);
    final String txPowerVal = getVal(opmRaw, 4);
    final String rxPowerVal = getVal(opmRaw, 5);

    return OnuData(
      oltId: this.oltId,
      id: id,
      name: configName.isNotEmpty ? configName : name,
      macAddress: macAddress,
      status: configStatus.isNotEmpty ? configStatus : status,
      fwVersion: configFw.isNotEmpty ? configFw : fwVersion,
      chipId: configChip.isNotEmpty ? configChip : chipId,
      ports: configPorts.isNotEmpty ? configPorts : ports,
      ctcStatus: ctcStatus.isNotEmpty ? ctcStatus : this.ctcStatus,
      ctcVer: ctcVerRaw.isNotEmpty ? ctcVerRaw : ctcVer,
      activate: activate,
      rtt: rtt,
      distance: distance,
      temperature: tempVal.isNotEmpty ? tempVal : temperature,
      txPower: txPowerVal.isNotEmpty ? txPowerVal : txPower,
      rxPower: rxPowerVal.isNotEmpty ? rxPowerVal : rxPower,
      onlineTime: lastUp.isNotEmpty ? lastUp : onlineTime,
      offlineTime: lastOff.isNotEmpty ? lastOff : offlineTime,
      offlineReason: offlineReason.isNotEmpty
          ? offlineReason
          : this.offlineReason,
      uptime: uptime,
      deregisterCnt: deregisterRaw.isNotEmpty ? deregisterRaw : deregisterCnt,
      firstUpTime: firstUp.isNotEmpty ? firstUp : firstUpTime,
      voltage: voltVal.isNotEmpty ? voltVal : voltage,
      biasCurrent: biasVal.isNotEmpty ? biasVal : biasCurrent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oltId': oltId,
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'status': status,
      'fwVersion': fwVersion,
      'chipId': chipId,
      'ports': ports,
      'ctcStatus': ctcStatus,
      'ctcVer': ctcVer,
      'activate': activate,
      'rtt': rtt,
      'distance': distance,
      'temperature': temperature,
      'txPower': txPower,
      'rxPower': rxPower,
      'onlineTime': onlineTime,
      'offlineTime': offlineTime,
      'offlineReason': offlineReason,
      'uptime': uptime,
      'deregisterCnt': deregisterCnt,
      'firstUpTime': firstUpTime,
      'voltage': voltage,
      'biasCurrent': biasCurrent,
    };
  }

  factory OnuData.fromJson(Map<String, dynamic> json) {
    return OnuData(
      oltId: json['oltId'] as String?,
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      macAddress: json['macAddress'] ?? "",
      status: json['status'] ?? "",
      fwVersion: json['fwVersion'] ?? "",
      chipId: json['chipId'] ?? "",
      ports: json['ports'] ?? "",
      ctcStatus: json['ctcStatus'] ?? "",
      ctcVer: json['ctcVer'] ?? "",
      activate: json['activate'] ?? "",
      rtt: json['rtt'] ?? "",
      distance: json['distance'] ?? "",
      temperature: json['temperature'] ?? "",
      txPower: json['txPower'] ?? "",
      rxPower: json['rxPower'] ?? "",
      onlineTime: json['onlineTime'] ?? "",
      offlineTime: json['offlineTime'] ?? "",
      offlineReason: json['offlineReason'] ?? "",
      uptime: json['uptime'] ?? "",
      deregisterCnt: json['deregisterCnt'] ?? "",
      firstUpTime: json['firstUpTime'] ?? "--",
      voltage: json['voltage'] ?? "--",
      biasCurrent: json['biasCurrent'] ?? "--",
    );
  }
}

/// Helper function to convert seconds into formatted uptime string matching OLT's sec2timeSimple JS function
String formatSecondsToUptime(int sec) {
  int years = 0;
  int yearsM = 0;
  int days = 0;
  int daysM = 0;
  int hours = 0;
  int hoursM = 0;
  int minutes = 0;
  int minM = 0;
  int seconds = 0;

  minM = sec ~/ 60;
  seconds = sec % 60;
  if (minM > 0) {
    hoursM = minM ~/ 60;
    minutes = minM % 60;
    if (hoursM > 0) {
      daysM = hoursM ~/ 24;
      hours = hoursM % 24;
      if (daysM > 0) {
        yearsM = daysM ~/ 356; // Matching 356-day OLT calculation
        days = daysM % 356;
        if (yearsM > 0) {
          years = yearsM;
        }
      }
    }
  }

  if (years > 0) {
    return "${years}Y ${days}D ${hours}H ${minutes}M";
  } else if (days > 0) {
    return "${days}D ${hours}H ${minutes}M";
  } else {
    return "${hours}H ${minutes}M ${seconds}S";
  }
}
