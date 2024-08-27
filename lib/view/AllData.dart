import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:cashier/main.dart';
import 'package:intl/intl.dart';

class AllData extends StatefulWidget {
  @override
  _AllDataState createState() => _AllDataState();
}

class _AllDataState extends State<AllData> {
  List<SalesData> _totalSalesData = [];
  List<DailySalesData> _dailySalesData = [];
  List<StockData> _stockData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedPieIndex = -1;
  String _selectedBarDate = '';
  Map<String, Color> _colorMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchStockData(),
        _fetchSalesData(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStockData() async {
    final stockResponse = await Supabase.instance.client
        .from('tbl_barang')
        .select('nama_barang, stock_barang');
    
    _stockData = stockResponse.map<StockData>((item) => 
      StockData(item['nama_barang'], item['stock_barang'])
    ).toList();
  }

  Future<void> _fetchSalesData() async {
    try {
      // Fetch all items from tbl_barang
      final itemsResponse = await Supabase.instance.client
          .from('tbl_barang')
          .select('id_barang, nama_barang');

      Map<String, String> itemNames = {};
      for (var item in itemsResponse) {
        itemNames[item['id_barang'].toString()] = item['nama_barang'];
      }

      // Fetch all transactions from tbl_history
      final historyResponse = await Supabase.instance.client
          .from('tbl_history')
          .select('items, tanggal_transaksi')
          .order('tanggal_transaksi');

      Map<String, int> totalSales = {};
      Map<String, Map<String, int>> dailySales = {};

      for (var transaction in historyResponse) {
        String date = DateFormat('dd-MM-yyyy').format(DateTime.parse(transaction['tanggal_transaksi']));
        Map<String, dynamic> items = jsonDecode(transaction['items']);
        
        dailySales.putIfAbsent(date, () => {});
        
        items.forEach((itemId, quantity) {
          String itemName = itemNames[itemId] ?? 'Unknown Item';
          int parsedQuantity = int.tryParse(quantity.toString()) ?? 0;
          totalSales[itemName] = (totalSales[itemName] ?? 0) + parsedQuantity;
          dailySales[date]![itemName] = (dailySales[date]![itemName] ?? 0) + parsedQuantity;
        });
      }

      // After fetching data, populate _allDates and _allItems
      List<String> allDates = dailySales.keys.toList()..sort();
      List<String> allItems = totalSales.keys.toList();

      // Create a complete dataset with 0 for missing values
      List<DailySalesData> completeData = [];
      for (String date in allDates) {
        for (String item in allItems) {
          completeData.add(DailySalesData(
            date,
            item,
            dailySales[date]?[item] ?? 0,
          ));
        }
      }

      setState(() {
        _dailySalesData = completeData;
        _totalSalesData = totalSales.entries.map((e) => SalesData(e.key, e.value)).toList();
        _isLoading = false;
        if (_totalSalesData.isEmpty) {
          _errorMessage = 'No sales data available.';
        }
      });
    } catch (e) {
      print('Error fetching sales data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grafik Penjualan dan Stok'),
        backgroundColor: Warna,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: Warna,
        backgroundColor: Colors.white,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Warna)))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        Text('Stok Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 350,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            primaryYAxis: NumericAxis(title: AxisTitle(text: 'Jumlah Stok')),
                            series: <CartesianSeries<dynamic, dynamic>>[
                              BarSeries<StockData, String>(
                                dataSource: _stockData,
                                xValueMapper: (StockData stock, _) => stock.itemName,
                                yValueMapper: (StockData stock, _) => stock.stockQuantity,
                                dataLabelSettings: const DataLabelSettings(isVisible: true),
                                pointColorMapper: (StockData stock, _) => _getColor(stock.itemName),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text('Total Penjualan per Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 450, // Increased from 300
                          child: SfCircularChart(
                            title: ChartTitle(text: 'Total Penjualan per Item'),
                            legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CircularSeries>[
                              PieSeries<SalesData, String>(
                                dataSource: _totalSalesData,
                                xValueMapper: (SalesData sales, _) => sales.itemName,
                                yValueMapper: (SalesData sales, _) => sales.quantity,
                                pointColorMapper: (SalesData sales, _) => _getColor(sales.itemName),
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16, // Increased from 13
                                  ),
                                ),
                                dataLabelMapper: (SalesData sales, _) => sales.quantity.toString(),
                                enableTooltip: true,
                                explode: true,
                                explodeIndex: _selectedPieIndex,
                                radius: '80%', // Added to increase pie size within the chart area
                                onPointTap: (ChartPointDetails details) {
                                  setState(() {
                                    _selectedPieIndex = details.pointIndex!;
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text('Penjualan Harian per Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 500, // Increased from 300
                          child: SfCartesianChart(
                            title: ChartTitle(text: 'Penjualan Harian per Item'),
                            primaryXAxis: DateTimeAxis(
                              dateFormat: DateFormat('dd-MM-yyyy'),
                              intervalType: DateTimeIntervalType.days,
                              majorGridLines: MajorGridLines(width: 0),
                            ),
                            primaryYAxis: NumericAxis(
                              title: AxisTitle(text: 'Jumlah Terjual'),
                              minimum: 0,
                              maximum: 12,
                              interval: 2,
                            ),
                            legend: Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: _totalSalesData
                                .map((e) => e.itemName)
                                .toSet()
                                .map((itemName) => ColumnSeries<DailySalesData, DateTime>(
                                  dataSource: _dailySalesData
                                      .where((sale) => sale.itemName == itemName && sale.quantity > 0)
                                      .toList()
                                    ..sort((a, b) => DateFormat('dd-MM-yyyy').parse(a.date).compareTo(DateFormat('dd-MM-yyyy').parse(b.date))),
                                  xValueMapper: (DailySalesData sales, _) => DateFormat('dd-MM-yyyy').parse(sales.date),
                                  yValueMapper: (DailySalesData sales, _) => sales.quantity,
                                  name: itemName,
                                  dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                  color: _getColor(itemName),
                                  width: 0.99, // Maximized width
                                  spacing: 0.01, // Minimized spacing
                                ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Color _getColor(String itemName) {
    if (!_colorMap.containsKey(itemName)) {
      final colors = <Color>[
        Colors.pink,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.amber,
        Colors.indigo,
        Colors.lime,
      ];
      _colorMap[itemName] = colors[_colorMap.length % colors.length];
    }
    return _colorMap[itemName]!;
  }
}

class StockData {
  final String itemName;
  final int stockQuantity;

  StockData(this.itemName, this.stockQuantity);
}

class SalesData {
  final String itemName;
  final int quantity;

  SalesData(this.itemName, this.quantity);
}

class DailySalesData {
  final String date;
  final String itemName;
  final int quantity;

  DailySalesData(this.date, this.itemName, this.quantity);
}