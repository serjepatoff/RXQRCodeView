# RXQRCodeView
RXQRCodeView is dead-simple QR-code view for both iOS and MacOS.

Just create it programmatically, for example:

```objective-c
RXQRCodeView *qrView = [RXQRCodeView alloc] initWithFrame:...]
qrView.text = @"Hello"; //or qrView.data = [NSData dataWithBytes:...];
qrView.foregroundColor = [UIColor redColor];
qrView.backgroundColor = [UIColor blackColor];
qrView.type = RXQRCodeTypeAztec; //default is RXQRCodeTypeQR
qrView.redundancy = RXQRCodeRedundancyHigh; //redundancy helps recover data from low quality images
```

OR

Place it in xib, wire an outlet, set properties, etc.
