import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/base_name_model.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../online_navigation_home_screen.dart';
import '../../services/company_service.dart';
import '../../services/branch_service.dart';
import '../../services/mobile_shift_service.dart';
import '../../services/default_data_service.dart';

enum _ShiftActionResult { continueWithExisting, closeAndOpenNew, cancel }

class SelectCompanyBranchScreen extends StatefulWidget {
  final User user;

  const SelectCompanyBranchScreen({super.key, required this.user});

  @override
  State<SelectCompanyBranchScreen> createState() => _SelectCompanyBranchScreenState();
}

class _SelectCompanyBranchScreenState extends State<SelectCompanyBranchScreen> {
  List<Company> _companies = [];
  Company? _selectedCompany;

  List<Branch> _branches = [];
  Branch? _selectedBranch;

  bool _isLoading = false;
  bool _dialogLoading = false; // Added this variable

  @override
  void initState() {
    super.initState();
    _selectedCompany = widget.user.branch?.company.value;
    _selectedBranch = widget.user.branch;
    
    // If both are already present, we can just skip to create shift directly
    if (_selectedCompany != null && _selectedBranch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createShiftAndContinue();
      });
    } else {
      _fetchCompanies();
      _fetchBranches();
    }
  }

  Future<void> _fetchCompanies() async {
    try {
      if (widget.user.companyId != null) {
        var companies = await CompanyService().getUserCompanies(widget.user);
        
        if (mounted) {
          setState(() {
            _companies = companies;
            if (_selectedCompany == null && _companies.isNotEmpty) {
              _selectedCompany = _companies.first;
            }
          });
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        var companiesJson = jsonEncode(companies.map((c) => c.toJson()).toList());
        await prefs.setString('onlineCompanies', companiesJson);
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  Future<void> _fetchBranches() async {
    try {
      var branches = await BranchService().fetchUserBranches();
      
      if (mounted) {
        setState(() {
          _branches = branches;
          if (_selectedBranch == null && _branches.isNotEmpty) {
            _selectedBranch = _branches.first;
          }
        });
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var branchesJson = jsonEncode(branches.map((b) => b.toJson()).toList());
      await prefs.setString('onlineBranches', branchesJson);
    } catch (e) {
      debugPrint("Error fetching branches: $e");
    }
  }

  void _showCompanySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Company'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _companies.length,
                  itemBuilder: (BuildContext context, int index) {
                    final company = _companies[index];
                    return ListTile(
                      title: Text(company.name!),
                      leading: const Icon(Icons.business),
                      trailing: _selectedCompany?.id == company.id
                          ? const Icon(Icons.check, color: AppTheme.vimbikaBlue)
                          : null,
                      onTap: _dialogLoading ? null : () {
                        setDialogState(() {
                          _dialogLoading = true;
                        });
                        setState(() {
                          _selectedCompany = company;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _dialogLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: _dialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBranchSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Branch'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _branches.length,
                  itemBuilder: (BuildContext context, int index) {
                    final branch = _branches[index];
                    return ListTile(
                      title: Text(branch.name!),
                      leading: const Icon(Icons.store),
                      trailing: _selectedBranch?.id == branch.id
                          ? const Icon(Icons.check, color: AppTheme.vimbikaBlue)
                          : null,
                      onTap: _dialogLoading ? null : () {
                        setDialogState(() {
                          _dialogLoading = true;
                        });
                        setState(() {
                          _selectedBranch = branch;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _dialogLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: _dialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createShiftAndContinue() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final shiftService = MobilePosShiftService();
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Check for an existing open shift
      final openShiftResponse = await shiftService.getOpenShift(widget.user.id!);
      final bool isShiftAvailable = openShiftResponse['available'] ?? false;

      if (isShiftAvailable) {
        final MobilePosShift existingShift = MobilePosShift.fromJson(openShiftResponse['item']);
        final DateTime openingDateTime = DateFormat(AppConstants.APP_DATE_TIME_FMT).parse(existingShift.openingTime!);
        final bool isSameDay = openingDateTime.year == DateTime.now().year &&
                               openingDateTime.month == DateTime.now().month &&
                               openingDateTime.day == DateTime.now().day;

        _ShiftActionResult? result;
        if (isSameDay) {
          // Prompt to log into existing shift
          if (!mounted) return;
          result = await showDialog<_ShiftActionResult>(
            context: context,
            barrierDismissible: false, // Prevent dialog from closing on outside tap
            builder: (BuildContext context) {
              bool dialogButtonLoading = false; // Local loading state for dialog buttons
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text('Open Shift Found'),
                    content: Text('An open shift from today was found ${existingShift.shiftReference}. Do you want to continue with it?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: dialogButtonLoading ? null : () async {
                          setDialogState(() {
                            dialogButtonLoading = true;
                          });
                          try {
                            await prefs.setString(AppConstants.keyCurrentOpenShift, existingShift.toJson());
                            if (!context.mounted) return;
                            if (mounted) {
                              // Check if default data needs to be fetched
                              final String? lastFetchedUserId = prefs.getString(AppConstants.keyLastFetchedUserId);
                              if (lastFetchedUserId != widget.user.id) {
                                final defaultDataService = DefaultDataService();
                                await defaultDataService.fetchAndSaveDefaultData(widget.user);
                                await prefs.setString(AppConstants.keyLastFetchedUserId, widget.user.id!);
                              }
                              Navigator.of(context).pop(_ShiftActionResult.continueWithExisting); // Close dialog
                            }
                          } catch (e) {
                            debugPrint("Error fetching default data: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to continue with shift: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                dialogButtonLoading = false;
                              });
                            }
                          }
                        },
                        child: dialogButtonLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue with Shift'),
                      ),
                      TextButton(
                        onPressed: dialogButtonLoading ? null : () async {
                          setDialogState(() {
                            dialogButtonLoading = true;
                          });
                          try {
                            // Close the existing shift
                            existingShift.closingTime = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
                            existingShift.isShiftClosed = true;
                            await shiftService.updateShift(existingShift);
                            if (!context.mounted) return;
                            if (mounted) {
                              Navigator.of(context).pop(_ShiftActionResult.closeAndOpenNew); // Close dialog
                            }
                          } catch (e) {
                            debugPrint("Error closing shift and creating new one: $e");
                            if (!context.mounted) return;
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to close shift and create new one: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                dialogButtonLoading = false;
                              });
                            }
                          }
                        },
                        child: dialogButtonLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Close shift & Open New'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        } else {
          // Prompt to close previous day's shift
          if (!mounted) return;
          result = await showDialog<_ShiftActionResult>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              bool dialogButtonLoading = false;
              final formattedOpeningDate = DateFormat('yyyy-MM-dd').format(openingDateTime);
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text('Previous Day\'s Shift Found'),
                    content: Text('An open shift from a previous day ($formattedOpeningDate, Shift: ${existingShift.shiftReference}) was found. Please close it to continue.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: dialogButtonLoading ? null : () async {
                          setDialogState(() {
                            dialogButtonLoading = true;
                          });
                          try {
                            // Close the existing shift
                            existingShift.closingTime = DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now());
                            existingShift.isShiftClosed = true;
                            await shiftService.updateShift(existingShift);
                            if (!context.mounted) return;
                            if (mounted) {
                              Navigator.of(context).pop(_ShiftActionResult.closeAndOpenNew); // Close dialog
                            }
                          } catch (e) {
                            debugPrint("Error closing previous shift: $e");
                            if (!context.mounted) return;
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to close previous shift: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                dialogButtonLoading = false;
                              });
                            }
                          }
                        },
                        child: dialogButtonLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Close shift & Open New'),
                      ),
                      TextButton(
                        onPressed: dialogButtonLoading ? null : () {
                          Navigator.of(context).pop(_ShiftActionResult.cancel); // Close dialog
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }

        if (result == _ShiftActionResult.continueWithExisting) {
          _navigateToHomeScreen();
          return;
        } else if (result != _ShiftActionResult.closeAndOpenNew) {
          return;
        }
      }

      // If no open shift is found, proceed to create a new one
      await _createNewShiftAndNavigate(shiftService);

    } catch (e) {
      debugPrint("Error in _createShiftAndContinue: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewShiftAndNavigate(MobilePosShiftService shiftService) async {
    if (!mounted) return;
    try {
      final newShift = MobilePosShift(
        userId: widget.user.id,
        company: BaseNameModel(id: _selectedCompany?.id, name: _selectedCompany?.name),
        shiftReference: 'SF${DateTime.now().millisecondsSinceEpoch}',
        openingTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        isShiftClosed: false,
        userFullName: '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'.trim(),
        synced: false,
        stopSync: false,
        active: true,
      );

      await shiftService.createShift(newShift);

      // Download all default data
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? lastFetchedUserId = prefs.getString(AppConstants.keyLastFetchedUserId);
        if (lastFetchedUserId != widget.user.id) {
          final defaultDataService = DefaultDataService();
          await defaultDataService.fetchAndSaveDefaultData(widget.user);
          await prefs.setString(AppConstants.keyLastFetchedUserId, widget.user.id!);
        }
      } catch (e) {
        debugPrint("Error fetching default data: $e");
      }

      _navigateToHomeScreen();
    } catch (e) {
      debugPrint("Error creating new shift: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create new shift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToHomeScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnlineNavigationHomeScreen(isOnline: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Select Company and Branch'),
        backgroundColor: AppTheme.vimbikaBlue,
        foregroundColor: AppTheme.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome!',
              style: AppTheme.display1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please confirm your company and branch details.',
              style: AppTheme.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: _companies.isNotEmpty ? _showCompanySelectionDialog : null,
              child: _buildInfoCard(
                title: 'Company',
                value: _selectedCompany?.name ?? 'N/A',
                icon: Icons.business,
                isInteractive: _companies.isNotEmpty,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _branches.isNotEmpty ? _showBranchSelectionDialog : null,
              child: _buildInfoCard(
                title: 'Branch',
                value: _selectedBranch?.name ?? 'N/A',
                icon: Icons.store,
                isInteractive: _branches.isNotEmpty,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vimbikaBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _createShiftAndContinue,
              child: _isLoading 
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Continue to Dashboard',
                    style: AppTheme.title.copyWith(color: AppTheme.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isInteractive = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.vimbikaBlue, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTheme.headline.copyWith(color: AppTheme.darkText),
                  ),
                ],
              ),
            ),
            if (isInteractive)
              const Icon(Icons.arrow_drop_down, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }
}