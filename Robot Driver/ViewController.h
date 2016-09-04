//
//  ViewController.h
//  Robot Driver
//
//  Created by Monnerat, David on 9/3/16.
//  Copyright © 2016 kettlepot Ventures Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CarduinoViewCell.h"

@interface ViewController : UIViewController <CBPeripheralDelegate, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource>

// Instance of Central Manager.
@property (strong, nonatomic) CBCentralManager *centralManager;
// Stores a list of discovered devices, the key being their UUID.
@property (strong, nonatomic) NSMutableDictionary *devices;
// Instance method, used to act when a peripheral is discovered.
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
// Instance method, used to act when a peripheral is selected to connect.
@property (strong, nonatomic) CBPeripheral *selectedPeripheral;
// Holds UUIDs.
@property (readonly, nonatomic) CFUUIDRef UUID;
// Stores peripheral characteristics.
@property (strong, nonatomic) CBCharacteristic *characteristics;
// Stores the advertising data of a peripheral.
@property (strong, nonatomic) NSMutableData *data;

@end

int counter;

