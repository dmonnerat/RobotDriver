//
//  ViewController.m
//  Robot Driver
//
//  Created by Monnerat, David on 9/3/16.
//  Copyright © 2016 kettlepot Ventures Limited. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, retain) NSString *rxData;
@property int counter;

//Outlets
@property (weak, nonatomic) IBOutlet UIButton *driveForward;
@property (weak, nonatomic) IBOutlet UIButton *driveLeft;
@property (weak, nonatomic) IBOutlet UIButton *driveRight;
@property (weak, nonatomic) IBOutlet UIButton *driveBack;
@property (weak, nonatomic) IBOutlet UISwitch *toggleSpinner;

@property (weak, nonatomic) IBOutlet UILabel *lblRXData;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *devicesView;

//Buttons in Devices Table.
@property (weak, nonatomic) IBOutlet UIButton *btnTest;
@property (weak, nonatomic) IBOutlet UIButton *btnBackFromDevices;
//BLE
@property (weak, nonatomic) IBOutlet UIButton *scanForDevices;

@property (weak, nonatomic) IBOutlet UIButton *btnMenu;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Allocates and initializes an instance of the CBCentralManager.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////// Bluetooth Low Energy /////////////////////

- (int)readRSSI
{
    CBPeripheral *thisPer = _selectedPeripheral;
    [thisPer readRSSI];
    
    int RSSI = [thisPer.RSSI intValue];
    return RSSI;
}

// Make sure iOS BT is on.  Then start scanning.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // You should test all scenarios
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In case Bluetooth is off.
        NSLog(@"Bluetooth is off");
        return;
        // Need to add code here stating unable to access Bluetooth.
    }
    if (central.state == CBCentralManagerStatePoweredOn) {
        //If it's on, scan for devices.
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    //NSLog(@"One  -- centralManagerDidUpdateState");
    //NSLog(@"One");
}

- (NSMutableDictionary *)devices
{
    // Make sure the device dictionary is empty.
    if (_devices == nil)
    {
        // Let's get the top 6 devices.
        _devices = [NSMutableDictionary dictionaryWithCapacity:6];
    }
    // Return a dictionary of devices.
    return _devices;
}

// Report what devices have been found.
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral");

    // Set peripheral.
    _discoveredPeripheral = peripheral;
    
    // Create a string for the conneceted peripheral.
    NSString * uuid = [[peripheral identifier] UUIDString];
    
    if (uuid) //Make sure we got the UUID.
    {
        //This sets the devices object.peripheral = uuid
        [self.devices setObject:peripheral forKey:uuid];
    }
    
    //Refresh data in the table.
    [self.tableView reloadData];
    
    //NSLog(@"centralManager didDiscoverPeripheral");
    //NSLog(@"Two -- centralManager didDiscoverPeripheral");
}

// Run this whenever we have connected to a device.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    // Set the peripheral delegate.
    peripheral.delegate = self;
    // Set the peripheral method's discoverServices to nil,
    // this searches for all services, its slower but inclusive.
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {NSLog(@"DISCOVER_CHAR - Error");return;}

    // Enumerate through all services on the connected peripheral.
    for (CBService * service in [peripheral services])
    {
        NSLog(@"DISCOVER_SERVICE - Service : %@",service);

        // Discover all characteristics for this service.
        [_selectedPeripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    // Enumerate through all services on the connected peripheral.
    for (CBCharacteristic * character in [service characteristics])
    {
        NSLog(@"DISCOVER_CHAR - Characteristic : %@",character);
        // Discover all descriptors for each characteristic.
        [_selectedPeripheral discoverDescriptorsForCharacteristic:character];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    //Store data from the UUID in byte format, save in the bytes variable.
    const char * bytes =[(NSData*)[[characteristic UUID] data] bytes];
    //Check to see if it is two bytes long, and they are FF and E1.
    if (bytes && strlen(bytes) == 2 && bytes[0] == (char)255 && bytes[1] == (char)225)
    {
        // Send the peripheral data to the MainViewController.
        _selectedPeripheral = peripheral;
        for (CBService * service in [_selectedPeripheral services])
        {
            
            for (CBCharacteristic * characteristic in [service characteristics])
            {
                // For every characteristic on every service, on the connected peripheral
                // set the setNotifyValue to true.
                NSLog(@"Setting notify to true %c", bytes[1]);
                
                [_selectedPeripheral setNotifyValue:true forCharacteristic:characteristic];
            }
        }
    }
}

- (void)sendValue:(NSString *) str
{
    for (CBService * service in [_selectedPeripheral services])
    {
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            if ((characteristic.properties & CBCharacteristicPropertyWrite) ||
                (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse))
            {
                //Do your Write here
                NSLog(@"DISCOVER_CHAR - Characteristic : %@",characteristic);
                NSLog(@"Attempting to write %@", str);
                // Write the str variable with all our movement data.
                [_selectedPeripheral writeValue:[str dataUsingEncoding:NSUTF8StringEncoding]
                              forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                self.rxData = @" ";

            }
            
        }
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
 if (error == nil) {
    NSLog(@"Got something back");
    NSString * str = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
    self.rxData = str;
    self.lblRXData.text = [NSString stringWithFormat:@"%@", str];
 }
 else {
     NSLog(@"Error reading characteristic %@",error);
 }
    
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error == nil) {
        NSLog(@"Successfully wrote characteristic");
    }
    else {
        NSLog(@"Error writing characteristic %@",error);
    }
}


////////////////////// Bluetooth Low Energy End //////////////////
- (IBAction)btnMenuTouchUp:(id)sender {
    //ViewController * fade = [[ViewController alloc] init];
    //[fade fadeDeviceMenuIn];
    NSLog(@"Menu");
    // Hide the devices list.
    [UIView beginAnimations:@"fade in" context:nil];
    [UIView setAnimationDuration:.30];
    self.devicesView.alpha = 1;
    self.devicesView.hidden=false;
    [UIView commitAnimations];
}

- (IBAction)btnBackFromDevices:(id)sender {
    // Hide the devices list.
    [UIView beginAnimations:@"fade in" context:nil];
    [UIView setAnimationDuration:.30];
    self.devicesView.alpha = 0;
    [UIView commitAnimations];
}
- (IBAction)btnSendTest:(id)sender {
    //[self sendValue:[NSString stringWithFormat:@"%c:", 250]];
    NSLog(@"Sending test...");
    [self sendValue:@"!off;"];
    //NSLog(@"Devices: %@", _devices);
    //NSLog(@"%i", [_devices count]);
}

# pragma mark - table controller
////////////////////// Device Table View //////////////////

- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //This counts how many items are in the deviceList array.
    return [self.devices count];
}


- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // This gets a sorted array from NSMutableDictionary.
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    // Setup a devices instance.
    CBPeripheral * devices = nil;
    
    
    // Go until we run out of devices.
    if ([indexPath row] < [uuids count])
    {
        // Set the peripherals based upon indexPath # from uuids array.
        devices = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
    }
    
    /////////////////////////LOADS CUSTOM CELL/////////////////////////////
    
    // This is a handle for the tableView.
    static NSString * carduinoTableIdentifier = @"iPadCarduinoTableCell";
    
    
    // Get cell objects.;
    CarduinoViewCell *cell = (CarduinoViewCell *)[tableView dequeueReusableCellWithIdentifier:carduinoTableIdentifier];
    // If cell is equal to nil....
    if (cell == nil){
        // Load the custom cell.
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:carduinoTableIdentifier owner:self options:nil];
        // Use the prototype.
        cell = [nib objectAtIndex:0];
    }
    
    /////////////////////////END/////////////////////////////
    
    // List all the devices in the table view.
    if([indexPath row] < [uuids count]){
        // Don't list a device if there isn't one.
        if (devices)
        {
            cell.deviceNameLabel.text = [devices name];
            cell.uuidLabel.text = [uuids objectAtIndex:[indexPath row]];
        }
    }
    
    // Add image on the left of each cell.
    cell.deviceImage.image = [UIImage imageNamed:@"oshw-logo-black.png"];
    // Sets background color for the cells.  Alpha = opacity.  Float, 0-1.
    // Will be used for device distance indication.  Let's have it as a base int.
    
    // Set the background color of the cells.
    cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:(1) alpha:1];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Create a sorted array of the found UUIDs.
    NSArray * uuids = [[self.devices allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    // Only get enough devices or listed cells.
    if ([indexPath row] < [uuids count])
    {
        // Set the peripheral based upon the indexPath; uuid being the array.
        _selectedPeripheral = [self.devices objectForKey:[uuids objectAtIndex:[indexPath row]]];
        
        // If there is a peripheral.
        if (_selectedPeripheral)
        {
            // Close current connection.
            [_centralManager cancelPeripheralConnection:_selectedPeripheral];
            // Connect to selected peripheral.
            [_centralManager connectPeripheral:_selectedPeripheral options:nil];
            // Hide the devices list.
            [UIView beginAnimations:@"fade in" context:nil];
            [UIView setAnimationDuration:1.0];
            self.devicesView.alpha = 0;
            [UIView commitAnimations];
        }
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Sets the height for each row to 90, the same size as the custom cell.
    return 60;
}

////////////////////// Device Table View End///////////////
- (IBAction)moveForward:(id)sender {
    [self sendValue:@"!forward;"];
}
- (IBAction)stopForward:(id)sender {
    [self sendValue:@"!off;"];

}
- (IBAction)moveLeft:(id)sender {
    //TODO: Need to fix motor on arduino so right = right
    [self sendValue:@"!right;"];
}
- (IBAction)stopLeft:(id)sender {
    [self sendValue:@"!off;"];
}
- (IBAction)moveRight:(id)sender {
    //TODO: Need to fix motor on arduino so left = left
    [self sendValue:@"!left;"];
}
- (IBAction)stopRight:(id)sender {
    [self sendValue:@"!off;"];
}
- (IBAction)moveBackward:(id)sender {
    [self sendValue:@"!reverse;"];
}
- (IBAction)stopBackward:(id)sender {
    [self sendValue:@"!off;"];
}

- (IBAction)changeSpinner:(id)sender {
    if (_toggleSpinner.isOn)
    {
        [self sendValue:@"!spinneron;"];
    }
    else
    {
        [self sendValue:@"!spinneroff;"];
        
    }
}

@end
