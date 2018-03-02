//
//  ViewController.m
//  ARRecorder
//
//  Created by 伍小华 on 2018/2/27.
//  Copyright © 2018年 伍小华. All rights reserved.
//

#import "ViewController.h"
#import "WXHARRecorder.h"
@interface ViewController () <ARSCNViewDelegate,ARSessionDelegate>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) WXHARRecorder *recorder;

@property (nonatomic, strong) UIImageView *imageView;
@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    
    self.sceneView.frame = self.view.bounds;
    [self.view addSubview:self.sceneView];
    
    self.sceneView.delegate = self;
    
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    self.sceneView.scene = scene;
    self.sceneView.session.delegate = self;
    
//    self.imageView = [[UIImageView alloc] init];
//    self.imageView.frame = CGRectMake(0, 0, 300, 300);
//    [self.view addSubview:self.imageView];
//    self.imageView.backgroundColor = [UIColor greenColor];
//    self.recorder.imageView = self.imageView;
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 100, 100);
    [backButton setTitle:@"back" forState:UIControlStateNormal];
    backButton.backgroundColor = [UIColor brownColor];
    [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    
    UIButton *setupbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [setupbutton setTitle:@"setup session" forState:UIControlStateNormal];
    setupbutton.frame = CGRectMake(0, 0, 200, 100);
    setupbutton.center = self.view.center;
    setupbutton.backgroundColor = [UIColor redColor];
    [setupbutton addTarget:self action:@selector(setupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setupbutton];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.backgroundColor = [UIColor brownColor];
    [startButton setTitle:@"start Recorder" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    startButton.frame = CGRectMake(0, 0, 200, 100);
    startButton.center = CGPointMake(setupbutton.center.x, setupbutton.center.y+150);
    [self.view addSubview:startButton];
}

//first step,start session
- (void)setupButtonAction:(UIButton *)button
{
    if (self.recorder.status == WXHARRecorderStatusUnknown) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                NSError *error;
                if ([self.recorder setupSession:&error]) {
                    [self.recorder startSession];
                    button.backgroundColor = [UIColor greenColor];
                } else {
                    WRITERLOG(@"Error: %@", [error localizedDescription]);
                }
            } else {
                NSLog(@"Microphone or Camera doesn't allowed");
            }
        }];
    }
}
//second step, start recorder
- (void)startButtonAction:(UIButton *)button
{
    if (self.recorder.status != WXHARRecorderStatusUnknown) {
        button.selected = !button.selected;
        if (button.selected) {
            [button setTitle:@"end Recorder" forState:UIControlStateNormal];
            [self.recorder startRecording:self.sceneView];
        } else {
            [button setTitle:@"start Recorder" forState:UIControlStateNormal];
            [self.recorder stopRecording:^(NSURL *filePath) {
                NSLog(@"%@",filePath);
            }];
        }
    } else {
        NSLog(@"must be setup recorder session");
    }
}

- (void)dealloc
{
    NSLog(@"View controller did dealloc !");
}
- (void)backButtonAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.sceneView.session pause];
}

//暂时不支持横盘录制，会出现问题
- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - Setter / Getter
- (WXHARRecorder *)recorder
{
    if (!_recorder) {
        _recorder = [[WXHARRecorder alloc] init];
    }
    return _recorder;
}
- (ARSCNView *)sceneView
{
    if (!_sceneView) {
        _sceneView = [[ARSCNView alloc] init];
    }
    return _sceneView;
}
@end
