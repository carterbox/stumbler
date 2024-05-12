# Stumbler

> [!NOTE]
> This project is now archived because the Mozilla Location Service (MLS) is retired. I started working on it before the formal announcement that MLS would shutdown and was putting on the finishing touches when MLS stopped accepting new data. I guess I should have done more reading of the news, because apparently there was some drama bout Mozilla being sued for patent infringement over this service?

A new WIFI stumbler for the Mozilla Location Service.

## TL;DR

Stumbler provides new information to the Mozilla Location Service, a database
which allows devices with WiFI but without GPS to locate themselves. Without
regular updates, the database becomes inaccurate.

## What and why?

This project is not affiliated in any way with Mozilla.

The Mozilla Location Service (MLS) is a database of WiFi networks and their
known locations to estimate your position. It's like GPS, but using millions of
Wifi beacons instead of tens of satellites. However, WiFi beacons move around
and are created/retired much more often than GPS satellies, so the database
must be regularly updated. That's where "stumbling" comes in. Mobile devices
with both GPS and WiFi report where and when they observe WiFi newtworks in
order to update the database.

Unfortunately, MozStumbler, the official data collection app for MLS on
Android, was retired in 2021 when there was not enough engineering
effort/interest in updating the framework for new platform restrictions in
Android 10+. Tower Collector still collects cellular networks for MLS and
OpenCellID, but there is no known WiFi network collector (besides this project).

GeoClue still uses WiFi via as its primary locating method on devices when GPS
and Cell are not available i.e. on desktop/laptop computers. In my experience,
my systems located me 1,000 miles from my actual position whenever WiFi was
enabled because the MLS database is out of date, so it's time to start updating
the MLS database again.

## What's different about this project?

It uses Flutter for the front end and third-party platform plugins for
accessing WiFi and location APIs. Platform restrictions on Android limit
how often Stumbler can make observations.
