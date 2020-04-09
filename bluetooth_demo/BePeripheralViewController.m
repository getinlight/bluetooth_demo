//
//  BePeripheralViewController.m
//  bluetooth_demo
//
//  Created by z on 2020/4/9.
//  Copyright © 2020 z. All rights reserved.
//

#import "BePeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString * const ServiceUUID1 =  @"FFF0";
static NSString * const notiyCharacteristicUUID =  @"FFF1";
static NSString * const readwriteCharacteristicUUID =  @"FFF2";
static NSString * const ServiceUUID2 =  @"FFE0";
static NSString * const readCharacteristicUUID =  @"FFE1";
static NSString * const LocalNameKey =  @"myPeripheral";

@interface BePeripheralViewController ()

@property (nonatomic, strong) CBPeripheralManager * peripheralManager;
@property (nonatomic, strong) NSTimer * timer;;
@property (nonatomic, assign) int serviceNum;;
@property (weak, nonatomic) IBOutlet UILabel *info;


@end

@implementation BePeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_info setText:@"正在打开设备"];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_peripheralManager stopAdvertising];
}

//配置bluetooch的
-(void)setUp{
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];

    /*
     可读写的characteristics
     properties：CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable | CBAttributePermissionsWriteable
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    //设置description
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    

    /*
     只读的Characteristic
     properties：CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];

    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    NSLog(@"%@",service1.UUID);
    
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    
    //添加后就会调用代理的- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
    [_peripheralManager addService:service1];
    [_peripheralManager addService:service2];
}

#pragma  mark -- CBPeripheralManagerDelegate

//peripheralManager状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
            //在这里判断蓝牙设别的状态  当开启了则可调用  setUp方法(自定义)
        case CBManagerStatePoweredOn:
            NSLog(@"powered on");
            [_info setText:[NSString stringWithFormat:@"设备名%@已经打开，可以使用center进行连接",LocalNameKey]];
            [self setUp];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"powered off");
            [_info setText:@"powered off"];
            break;
            
        default:
            break;
    }
}

//perihpheral添加了service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error == nil) {
        _serviceNum++;
    }

    //因为我们添加了2个服务，所以想两次都添加完成后才去发送广播
    if (_serviceNum==2) {
        //添加服务后可以在此向外界发出通告 调用完这个方法后会调用代理的
        //(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
        [_peripheralManager startAdvertising:@{
                                              CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ServiceUUID1],[CBUUID UUIDWithString:ServiceUUID2]],
                                              CBAdvertisementDataLocalNameKey : LocalNameKey
                                             }
         ];
        
    }
    
}

//peripheral开始发送advertising
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"in peripheralManagerDidStartAdvertisiong");
}

//订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"订阅了 %@的数据",characteristic.UUID);
    //每秒执行一次给主设备发送一个当前时间的秒数
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
}

//取消订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"取消订阅 %@的数据",characteristic.UUID);
    //取消回应
    [_timer invalidate];
}

//发送数据，发送当前时间的秒数
-(BOOL)sendData:(NSTimer *)t {
    CBMutableCharacteristic *characteristic = t.userInfo;
    NSDateFormatter *dft = [[NSDateFormatter alloc]init];
    [dft setDateFormat:@"ss"];
    NSLog(@"%@",[dft stringFromDate:[NSDate date]]);
    
    //执行回应Central通知数据
    return  [_peripheralManager updateValue:[[dft stringFromDate:[NSDate date]] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
    
}


//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
    
}

//
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
    
}

@end
