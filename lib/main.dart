import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // Add test devices (replace with your test device ID)
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['YOUR_TEST_DEVICE_ID']),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BarcodeInputScreen(),
    );
  }
}

class BarcodeInputScreen extends StatefulWidget {
  const BarcodeInputScreen({super.key});

  @override
  State<BarcodeInputScreen> createState() => _BarcodeInputScreenState();
}

class _BarcodeInputScreenState extends State<BarcodeInputScreen> {
  final TextEditingController _controller = TextEditingController();
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;
    print('Starting to load rewarded ad...');

    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-2074110571948162/3704927434' // ca-app-pub-3940256099942544/5224354917
          : 'ca-app-pub-3940256099942544/1712485313',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('Ad loaded successfully. Ad: ${ad.responseInfo}');
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              print('Ad showed fullscreen content.');
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              print('Ad dismissed');
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              print('Failed to show ad: $error');
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: ${error.message}');
          print('Error code: ${error.code}');
          print('Error domain: ${error.domain}');
          setState(() {
            _rewardedAd = null;
            _isAdLoading = false;
          });
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      print('Showing rewarded ad...');
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward of ${reward.amount} ${reward.type}');
          _generateBarcodes();
        },
      );
    } else {
      print('Rewarded ad is not ready. Current state:');
      print('Is ad loading: $_isAdLoading');
      print('RewardedAd object: $_rewardedAd');
      _loadRewardedAd();
      _generateBarcodes();
    }
  }

  void _generateBarcodes() {
    final codes = _controller.text
        .split('\n')
        .where((code) => code.trim().isNotEmpty)
        .toList();
    if (codes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeListScreen(codes: codes),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Enter barcodes (one per line)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showRewardedAd,
              child: const Text('Generate Barcodes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}

class BarcodeListScreen extends StatefulWidget {
  final List<String> codes;

  const BarcodeListScreen({super.key, required this.codes});

  @override
  State<BarcodeListScreen> createState() => _BarcodeListScreenState();
}

class _BarcodeListScreenState extends State<BarcodeListScreen> {
  Set<String> processedCodes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Barcodes'),
      ),
      body: ListView.builder(
        itemCount: widget.codes.length,
        itemBuilder: (context, index) {
          final code = widget.codes[index];
          final isProcessed = processedCodes.contains(code);

          return ListTile(
            title: Text(
              code,
              style: TextStyle(
                color: isProcessed ? Colors.grey : Colors.black,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarcodeDetailScreen(code: code),
                ),
              );
              setState(() {
                processedCodes.add(code);
              });
            },
          );
        },
      ),
    );
  }
}

class BarcodeDetailScreen extends StatelessWidget {
  final String code;

  const BarcodeDetailScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(code, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: code,
                width: 300,
                height: 150,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
