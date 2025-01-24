import 'package:flutter/material.dart';
import 'package:get/get.dart';
class NewStockRequestScreen extends GetView  {
  const NewStockRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Stock Request'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Conditionally show either the DropdownButton or the Search TextField
                    saleController.isSearching.value
                        ? Expanded(
                      child: TextField(
                        controller: saleController.searchTextEditingController,
                        decoration: InputDecoration(
                          hintText: 'Search Items...',
                          border: OutlineInputBorder(),
                          prefixIcon: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              saleController.searchTextEditingController
                                  .clear();
                              saleController.isSearching.value =
                              false; // Hide search field

                              final allItemsCategory = saleController.categories
                                  .firstWhere(
                                    (category) => category.id == "All Items",
                                orElse: () => saleController.categories.first,
                              );
                              saleController.selectedCategory.value =
                                  allItemsCategory;


                              saleController.filterProducts(query: '',
                                  category: saleController.selectedCategory
                                      .value?.id);
                            },
                          ),
                        ),
                        onChanged: (query) {
                          // saleController.filterProducts(query);
                          saleController.filterProducts(query: query,
                              category: saleController.selectedCategory.value
                                  ?.name); // Filter based on search query and category
                        },
                      ),
                    )
                        : Expanded(
                      child: DropdownButton<BaseNameModel>(
                        value: saleController.selectedCategory.value,
                        isExpanded: true,
                        // Make the dropdown take full width
                        items: saleController.categories.map((category) {
                          return DropdownMenuItem<BaseNameModel>(
                            value: category,
                            child: Text(category.name!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          saleController.isCatSelected.value = true;
                          saleController.selectedCategory.value = value!;
                          // saleController.filterProducts(value.name!);
                          saleController.filterProducts(category: value
                              .id!); // Filter based on selected category

                        },
                        hint: Text("Select Category"),
                      ),
                    ),
                    // Search Icon
                    if (!saleController.isSearching
                        .value) // Show search icon only when not searching
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          saleController.isSearching.value =
                          true; // Show search field
                          saleController.selectedCategory.value =
                              BaseNameModel(id: "All Items", name: "All Items");
                          saleController.filterProducts(query: '',
                              category: saleController.selectedCategory.value
                                  ?.id);
                        },
                      ),
                  ],
                );
              }),
            ),
          ],
        )
      ),
    );
  }
}
