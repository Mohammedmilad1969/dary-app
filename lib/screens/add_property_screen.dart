import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../providers/auth_provider.dart';
import '../services/property_service.dart' as property_service;
import '../services/persistence_service.dart';
import '../services/image_upload_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _addressController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _dailyRentController = TextEditingController();
  final _depositController = TextEditingController();

  PropertyType _selectedType = PropertyType.apartment;
  PropertyStatus _selectedStatus = PropertyStatus.forSale;
  PropertyCondition _selectedCondition = PropertyCondition.good;
  
  bool _hasBalcony = false;
  bool _hasGarden = false;
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasGym = false;
  bool _hasSecurity = false;
  bool _hasElevator = false;
  bool _hasAC = false;
  bool _hasHeating = false;
  bool _hasFurnished = false;
  bool _hasPetFriendly = false;
  bool _hasNearbySchools = false;
  bool _hasNearbyHospitals = false;
  bool _hasNearbyShopping = false;
  bool _hasPublicTransport = false;
  
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _addressController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _floorsController.dispose();
    _yearBuiltController.dispose();
    _monthlyRentController.dispose();
    _dailyRentController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.maxImages ?? 'You can upload a maximum of 10 images.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(10 - _selectedImages.length));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.failedToPickImages ?? 'Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Create property object
        final property = Property(
          id: '', // Will be set by Firebase
          userId: currentUser.id, // Associate with current user
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.tryParse(_priceController.text) ?? 0.0,
          sizeSqm: int.tryParse(_sizeController.text) ?? 0,
          city: _cityController.text.trim(),
          neighborhood: _neighborhoodController.text.trim(),
          address: _addressController.text.trim(),
          bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
          bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
          floors: int.tryParse(_floorsController.text) ?? 1,
          yearBuilt: int.tryParse(_yearBuiltController.text) ?? 0,
          type: _selectedType,
          status: _selectedStatus,
          condition: _selectedCondition,
          hasBalcony: _hasBalcony,
          hasGarden: _hasGarden,
          hasParking: _hasParking,
          hasPool: _hasPool,
          hasGym: _hasGym,
          hasSecurity: _hasSecurity,
          hasElevator: _hasElevator,
          hasAC: _hasAC,
          hasHeating: _hasHeating,
          hasFurnished: _hasFurnished,
          hasPetFriendly: _hasPetFriendly,
          hasNearbySchools: _hasNearbySchools,
          hasNearbyHospitals: _hasNearbyHospitals,
          hasNearbyShopping: _hasNearbyShopping,
          hasPublicTransport: _hasPublicTransport,
          monthlyRent: double.tryParse(_monthlyRentController.text) ?? 0.0,
          dailyRent: double.tryParse(_dailyRentController.text) ?? 0.0,
          deposit: double.tryParse(_depositController.text) ?? 0.0,
          contactPhone: currentUser.phone ?? '',
          contactEmail: currentUser.email ?? '',
          agentName: currentUser.name ?? '',
          imageUrls: [], // TODO: Upload images to Firebase Storage
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          views: 0,
          isFeatured: false,
          isVerified: false,
          isBoosted: false,
        );

        // Upload images first
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          setState(() {
            _isUploadingImages = true;
          });
          
          // Create a temporary property ID for image uploads
          final tempPropertyId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading ${_selectedImages.length} images...'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          
          try {
            imageUrls = await ImageUploadService.uploadImages(_selectedImages, tempPropertyId);
            
            if (imageUrls.isEmpty) {
              throw Exception('Failed to upload images');
            }
          } finally {
            setState(() {
              _isUploadingImages = false;
            });
          }
        }

        // Create property with uploaded image URLs
        final propertyWithImages = Property(
          id: property.id,
          userId: property.userId,
          title: property.title,
          description: property.description,
          price: property.price,
          sizeSqm: property.sizeSqm,
          city: property.city,
          neighborhood: property.neighborhood,
          address: property.address,
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          floors: property.floors,
          yearBuilt: property.yearBuilt,
          type: property.type,
          status: property.status,
          condition: property.condition,
          hasBalcony: property.hasBalcony,
          hasGarden: property.hasGarden,
          hasParking: property.hasParking,
          hasPool: property.hasPool,
          hasGym: property.hasGym,
          hasSecurity: property.hasSecurity,
          hasElevator: property.hasElevator,
          hasAC: property.hasAC,
          hasHeating: property.hasHeating,
          hasFurnished: property.hasFurnished,
          hasPetFriendly: property.hasPetFriendly,
          hasNearbySchools: property.hasNearbySchools,
          hasNearbyHospitals: property.hasNearbyHospitals,
          hasNearbyShopping: property.hasNearbyShopping,
          hasPublicTransport: property.hasPublicTransport,
          monthlyRent: property.monthlyRent,
          dailyRent: property.dailyRent,
          deposit: property.deposit,
          contactPhone: property.contactPhone,
          contactEmail: property.contactEmail,
          agentName: property.agentName,
          imageUrls: imageUrls, // Use uploaded image URLs
          createdAt: property.createdAt,
          updatedAt: property.updatedAt,
          views: property.views,
          isFeatured: property.isFeatured,
          isVerified: property.isVerified,
          isBoosted: property.isBoosted,
          boostPackageName: property.boostPackageName,
          boostExpiresAt: property.boostExpiresAt,
        );

        // Create property using PropertyService
        final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
        final persistenceService = Provider.of<PersistenceService>(context, listen: false);
        
        final propertyId = await propertyService.createProperty(propertyWithImages);
        
        if (propertyId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.propertyAddedSuccessfully ?? 'Property added successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          _clearForm();
          context.go('/'); // Navigate back to home
        } else {
          throw Exception('Failed to create property');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _sizeController.clear();
    _addressController.clear();
    _neighborhoodController.clear();
    _cityController.clear();
    _bedroomsController.clear();
    _bathroomsController.clear();
    _floorsController.clear();
    _yearBuiltController.clear();
    _monthlyRentController.clear();
    _dailyRentController.clear();
    _depositController.clear();
    
    _selectedType = PropertyType.apartment;
    _selectedStatus = PropertyStatus.forSale;
    _selectedCondition = PropertyCondition.good;
    
    _hasBalcony = false;
    _hasGarden = false;
    _hasParking = false;
    _hasPool = false;
    _hasGym = false;
    _hasSecurity = false;
    _hasElevator = false;
    _hasAC = false;
    _hasHeating = false;
    _hasFurnished = false;
    _hasPetFriendly = false;
    _hasNearbySchools = false;
    _hasNearbyHospitals = false;
    _hasNearbyShopping = false;
    _hasPublicTransport = false;
    
    _selectedImages = [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      return _buildLoginRequiredScreen(context, l10n);
    }

    return Column(
      children: [
        AppBar(
          title: Text(l10n?.addPropertyTitle ?? 'Add Property'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  _buildSectionTitle(l10n?.basicInformation ?? 'Basic Information'),
                  
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: l10n?.propertyTitle ?? 'Property Title',
                      hintText: l10n?.enterPropertyTitle ?? 'Enter property title',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.pleaseEnterTitle ?? 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: l10n?.description ?? 'Description',
                      hintText: l10n?.describeYourProperty ?? 'Describe your property',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.pleaseEnterDescription ?? 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Property Type and Status Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PropertyType>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: l10n?.propertyType ?? 'Property Type',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.home),
                          ),
                          items: PropertyType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.typeDisplayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<PropertyStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: l10n?.propertyStatus ?? 'Property Status',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.sell),
                          ),
                          items: PropertyStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.statusDisplayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price Field (LYD)
                  TextFormField(
                    controller: _priceController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Price (LYD)',
                      hintText: 'Enter price in Libyan Dinar',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Size Field
                  TextFormField(
                    controller: _sizeController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: l10n?.size ?? 'Size (sqm)',
                      hintText: l10n?.enterSize ?? 'Enter size in square meters',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.square_foot),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.pleaseEnterSize ?? 'Please enter the size';
                      }
                      if (double.tryParse(value) == null) {
                        return l10n?.pleaseEnterValidSize ?? 'Please enter a valid size';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rent Pricing (for rent properties)
                  if (_selectedStatus == PropertyStatus.forRent) ...[
                    Text(
                      'Rent Pricing',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _monthlyRentController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Monthly Rent (LYD)',
                              hintText: 'Enter monthly rent',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_month),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter monthly rent';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid rent amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dailyRentController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Daily Rent (LYD)',
                              hintText: 'Enter daily rent',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.today),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter daily rent';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid rent amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _depositController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Security Deposit (LYD)',
                        hintText: 'Enter deposit amount',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter deposit amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid deposit amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location Information Section
                  _buildSectionTitle(l10n?.locationInformation ?? 'Location Information'),
                  
                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter full address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Neighborhood and City Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _neighborhoodController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Neighborhood',
                            hintText: 'Enter neighborhood',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the neighborhood';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'City',
                            hintText: 'Enter city',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the city';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Property Details Section
                  _buildSectionTitle(l10n?.propertyDetails ?? 'Property Details'),
                  
                  // Bedrooms, Bathrooms, Floors Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedroomsController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Bedrooms',
                            hintText: 'Number of bedrooms',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.bed),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of bedrooms';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _bathroomsController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Bathrooms',
                            hintText: 'Number of bathrooms',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.bathtub),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of bathrooms';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _floorsController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Floors',
                            hintText: 'Number of floors',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.layers),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of floors';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Year Built and Condition Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearBuiltController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Year Built',
                            hintText: 'e.g., 2020',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter year built';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid year';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<PropertyCondition>(
                          value: _selectedCondition,
                          decoration: InputDecoration(
                            labelText: 'Condition',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.build),
                          ),
                          items: PropertyCondition.values.map((condition) {
                            return DropdownMenuItem(
                              value: condition,
                              child: Text(condition.conditionDisplayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCondition = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Features Section
                  _buildSectionTitle(l10n?.features ?? 'Features'),
                  
                  // Property Features Grid
                  _buildFeaturesGrid(),
                  const SizedBox(height: 24),

                  // Contact Information Section
                  _buildSectionTitle('Your Contact Information'),
                  
                  // Display user's contact info (read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact information will be taken from your profile:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Name: ${authProvider.currentUser?.name ?? 'Not available'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Phone: ${authProvider.currentUser?.phone ?? 'Not available'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Email: ${authProvider.currentUser?.email ?? 'Not available'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Upload Section
                  _buildSectionTitle(l10n?.images ?? 'Images'),
                  
                  Text(
                    '${l10n?.uploadImages ?? 'Upload Images'} (${_selectedImages.length}/10)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image),
                    label: Text(l10n?.selectImages ?? 'Select Images'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _selectedImages[index].path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isSubmitting || _isUploadingImages) ? null : _submitForm,
                      icon: (_isSubmitting || _isUploadingImages)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isUploadingImages 
                          ? 'Uploading Images...' 
                          : _isSubmitting 
                            ? (l10n?.addingProperty ?? 'Adding Property...') 
                            : (l10n?.addPropertyButton ?? 'Add Property')
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          // Property Features Section
          Text(
            'Property Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildSwitchTile('Balcony', Icons.balcony, _hasBalcony, (value) => setState(() => _hasBalcony = value)),
              _buildSwitchTile('Garden', Icons.yard, _hasGarden, (value) => setState(() => _hasGarden = value)),
              _buildSwitchTile('Parking', Icons.local_parking, _hasParking, (value) => setState(() => _hasParking = value)),
              _buildSwitchTile('Pool', Icons.pool, _hasPool, (value) => setState(() => _hasPool = value)),
              _buildSwitchTile('Gym', Icons.fitness_center, _hasGym, (value) => setState(() => _hasGym = value)),
              _buildSwitchTile('Security', Icons.security, _hasSecurity, (value) => setState(() => _hasSecurity = value)),
              _buildSwitchTile('Elevator', Icons.elevator, _hasElevator, (value) => setState(() => _hasElevator = value)),
              _buildSwitchTile('AC', Icons.ac_unit, _hasAC, (value) => setState(() => _hasAC = value)),
              _buildSwitchTile('Heating', Icons.thermostat, _hasHeating, (value) => setState(() => _hasHeating = value)),
              _buildSwitchTile('Furnished', Icons.chair, _hasFurnished, (value) => setState(() => _hasFurnished = value)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Lifestyle Features Section
          Text(
            'Lifestyle Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildSwitchTile('Pet Friendly', Icons.pets, _hasPetFriendly, (value) => setState(() => _hasPetFriendly = value)),
              _buildSwitchTile('Nearby Schools', Icons.school, _hasNearbySchools, (value) => setState(() => _hasNearbySchools = value)),
              _buildSwitchTile('Nearby Hospitals', Icons.local_hospital, _hasNearbyHospitals, (value) => setState(() => _hasNearbyHospitals = value)),
              _buildSwitchTile('Nearby Shopping', Icons.shopping_cart, _hasNearbyShopping, (value) => setState(() => _hasNearbyShopping = value)),
              _buildSwitchTile('Public Transport', Icons.directions_transit, _hasPublicTransport, (value) => setState(() => _hasPublicTransport = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      secondary: Icon(
        icon,
        color: Colors.green[600],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildLoginRequiredScreen(BuildContext context, AppLocalizations? l10n) {
    return Column(
      children: [
        AppBar(
          title: Text(l10n?.addPropertyTitle ?? 'Add Property'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Login Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please login to add properties to the platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}