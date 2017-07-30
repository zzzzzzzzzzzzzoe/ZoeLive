# 基于VideoToolbox实现的硬编码RTMP推流（iOS主播端） ZoeLivePusher

## 音／视频获取
- 通过AVCaptureInput设置设备的input和output,video,audio设置成data输入。
- 配置AVCaptureSession，装入input和output,start Session.
- 通过AVCaptureVideoPreviewLayer获取视频图像显示在要显示的地方。
- 通过<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>得到音/视频data.

## acc/h264硬编码
- 
