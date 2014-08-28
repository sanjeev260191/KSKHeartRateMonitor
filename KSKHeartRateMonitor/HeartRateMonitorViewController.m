//
//  HeartRateMonitorViewController.m
//  HeartRateMonitor
//
//  Created by Sanjeeva on 2/3/14.
//  Copyright (c) 2014 Sanjeeva. All rights reserved.
//

#import "HeartRateMonitorViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>
#define DEVICE_INFO_SERVICE_UUID @"180A"
#define HEART_RATE_SERVICE_UUID @"180D"

#define MEASUREMENT_CHARACTERISTIC_UUID @"2A37"
#define BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"
#define MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"
@interface HeartRateMonitorViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>{
    CBCentralManager* myCentralManager;
    CBService *interestingService;
    CBCharacteristic *interestingCharacteristic;
    int i;
}
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartRateBPM;
@property (weak, nonatomic) IBOutlet UILabel *deviceInfo;
@property (strong, nonatomic) CBPeripheral *connectingPeripheral;
@property (nonatomic, strong) NSString   *bodyData;
@property (nonatomic, strong) NSString   *manufacturer;
@property (assign) uint16_t heartRate;

@end

@implementation HeartRateMonitorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Hear Beat Report";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if(central.state==CBCentralManagerStatePoweredOn)
    {
        //Now do your scanning and retrievals
        NSLog(@"scanning started");
        self.statusLabel.text = @"scanning started";
        [myCentralManager scanForPeripheralsWithServices:nil options:nil];
    }else{
        self.statusLabel.text = @"Error occured. Check if bluetooth is on";
    }
}
- (void)centralManager:(CBCentralManager *)central

 didDiscoverPeripheral:(CBPeripheral *)peripheral

     advertisementData:(NSDictionary *)advertisementData

                  RSSI:(NSNumber *)RSSI {
    
    CBUUID *check = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
    
    NSLog(@"Discovered %@", check);
    self.statusLabel.text = [NSString stringWithFormat:@"Discovered %@", check];
    
    NSLog(@"Discovered %@", peripheral.name);
    self.statusLabel.text = [NSString stringWithFormat:@"Discovered %@", peripheral.name];
    if ([peripheral.name  isEqual: @"Wahoo HRM v2.1"]) {
        [myCentralManager stopScan];
        
        NSLog(@"Scanning stopped");
        self.statusLabel.text = @"scanning stopped";
        self.connectingPeripheral = peripheral;
        [myCentralManager connectPeripheral:self.connectingPeripheral options:nil];
    }
    
    
   
    
}
- (void)centralManager:(CBCentralManager *)central

  didConnectPeripheral:(CBPeripheral *)peripheral {
    
    
    
    NSLog(@"Peripheral connected");
    self.statusLabel.text = @"Peripheral connected";
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral

didDiscoverServices:(NSError *)error {
    
    
    
    for (CBService *service in peripheral.services) {
        
        NSLog(@"Discovered service %@", service.UUID);
         self.statusLabel.text = [NSString stringWithFormat:@"Discovered service %@", service.UUID];
        
        interestingService = service;
        NSLog(@"Discovering characteristics for service %@", interestingService.UUID);
         self.statusLabel.text = [NSString stringWithFormat:@"Discovering characteristics for service %@", interestingService.UUID];
        [self.connectingPeripheral discoverCharacteristics:nil forService:interestingService];
    }
    
    
}
- (void)peripheral:(CBPeripheral *)peripheral

didDiscoverCharacteristicsForService:(CBService *)service

             error:(NSError *)error {
    
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180D"]])  {
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"Discovered characteristic %@", characteristic.UUID);
        self.statusLabel.text = [NSString stringWithFormat:@"Discovered characteristic %@", characteristic.UUID];
        interestingCharacteristic = characteristic;
        
        // Request heart rate notifications
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MEASUREMENT_CHARACTERISTIC_UUID]]) {
            [self.connectingPeripheral setNotifyValue:YES forCharacteristic:characteristic];
            NSLog(@"Found heart rate measurement characteristic");
            self.statusLabel.text = @"Found heart rate measurement characteristic";
        }
        // Request body sensor location
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BODY_LOCATION_CHARACTERISTIC_UUID]]) {
            [self.connectingPeripheral readValueForCharacteristic:characteristic];
            NSLog(@"Found body sensor location characteristic");
            self.statusLabel.text = @"Found body sensor location characteristic";
        }
    }
    }
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:DEVICE_INFO_SERVICE_UUID]])  {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
                [self.connectingPeripheral readValueForCharacteristic:characteristic];
                NSLog(@"Found a device manufacturer name characteristic");
                self.statusLabel.text = @"Found a device manufacturer name characteristic";
            }
        }
    }
    

    
}

- (void)peripheral:(CBPeripheral *)peripheral

didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic

             error:(NSError *)error {
    
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MEASUREMENT_CHARACTERISTIC_UUID]]) {
        // Get the Heart Rate Monitor BPM
        [self getHeartBPMData:characteristic error:error];
    }
    // Retrieve the characteristic value for manufacturer name received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
        [self getManufacturerName:characteristic];
    }
    // Retrieve the characteristic value for the body sensor location received
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BODY_LOCATION_CHARACTERISTIC_UUID]]) {
        [self getBodyLocation:characteristic];
    }
    
    // Add your constructed device information to your UITextView
    self.deviceInfo.text = [NSString stringWithFormat:@"%@ \n %@", self.bodyData, self.manufacturer];
    
}
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0) {
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
    }
    else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    // Display the heart rate value to the UI if no error occurred
    if( (characteristic.value)  || !error ) {
        self.heartRate = bpm;
        self.heartRateBPM.text = [NSString stringWithFormat:@"%i bpm", bpm];
    }
    return;
}
- (void) getManufacturerName:(CBCharacteristic *)characteristic
{
    NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    self.manufacturer = [NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];
    return;
}
- (void) getBodyLocation:(CBCharacteristic *)characteristic
{
    NSData *sensorData = [characteristic value];
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData ) {
        uint8_t bodyLocation = bodyData[0];
        self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"];
    }
    else {
        self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
    }
    return;
}

@end


