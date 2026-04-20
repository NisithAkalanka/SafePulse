import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'negotiation_chat.dart';
import 'seller_reviews_screen.dart';

class ItemDetails extends StatefulWidget {
  final String? docId;
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? itemDescription;
  final String? itemCondition;
  final String? sellerId;

  const ItemDetails({
    super.key,
    this.docId,
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.itemDescription,
    this.itemCondition,
    this.sellerId,
  });

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  bool isFav = false;
  bool isSaved = false;
  bool isReported = false;
  String sellerName = "Loading...";

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _fetchSellerName();
  }

  void _fetchSellerName() async {
    if (widget.sellerId == null || widget.sellerId!.isEmpty) {
      setState(() => sellerName = "Verified Seller");
      return;
    }
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.sellerId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          sellerName =
              data?['username'] ?? data?['first_name'] ?? "Campus Member";
        });
      } else {
        setState(() => sellerName = "Verified Student");
      }
    } catch (e) {
      setState(() => sellerName = "SafePulse User");
    }
  }

  void _checkInitialStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId == null) return;
    final docPath = "${uid}_${widget.docId}";

    var favDoc = await FirebaseFirestore.instance
        .collection('user_favourites')
        .doc(docPath)
        .get();
    if (favDoc.exists) setState(() => isFav = true);

    var savedDoc = await FirebaseFirestore.instance
        .collection('user_saved')
        .doc(docPath)
        .get();
    if (savedDoc.exists) setState(() => isSaved = true);

    var itemDoc = await FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .get();
    if (itemDoc.exists && itemDoc.data()?['reported'] == true) {
      setState(() => isReported = true);
    }
  }

  void _reportItemAction() async {
    if (widget.docId == null || isReported) return;
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .update({
        'reported': true,
      });
      setState(() => isReported = true);
      _snack("Security Alert: Item Reported to Administration.");
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _toggleCollection(
    String colName,
    bool currentStatus,
    Function(bool) updater,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId == null) return;
    final docPath = "${uid}_${widget.docId}";

    try {
      if (currentStatus) {
        await FirebaseFirestore.instance
            .collection(colName)
            .doc(docPath)
            .delete();
        setState(() => updater(false));
        _snack("Removed!");
      } else {
        await FirebaseFirestore.instance.collection(colName).doc(docPath).set({
          'userId': uid,
          'listingId': widget.docId,
          'name': widget.itemName,
          'price': widget.itemPrice,
          'image': widget.itemImage,
          'sellerId': widget.sellerId,
          'createdAt': Timestamp.now(),
        });
        setState(() => updater(true));
        _snack("Saved successfully!");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  Widget _buildSellerRatingPreview(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isMyPost,
  ) {
    if (widget.sellerId == null || widget.sellerId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marketplace_reviews')
          .where('sellerId', isEqualTo: widget.sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;

        double total = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['rating'] ?? 0).toDouble();
        }

        final double average = docs.isEmpty ? 0 : total / docs.length;

        final sortedDocs = [...docs];
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTime = aData['createdAt'];
          final bTime = bData['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          if (aTime is Timestamp) return -1;
          if (bTime is Timestamp) return 1;
          return 0;
        });

        final recentReviews = sortedDocs.take(2).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Seller Ratings & Reviews",
                style: TextStyle(
                  color: gRedStart,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    average.toStringAsFixed(1),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${docs.length} review${docs.length == 1 ? '' : 's'}",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (recentReviews.isEmpty)
                Text(
                  "No reviews yet for this seller",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (recentReviews.isNotEmpty)
                ...recentReviews.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  DateTime? time;
                  if (data['createdAt'] is Timestamp) {
                    time = (data['createdAt'] as Timestamp).toDate();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: gRedStart.withOpacity(0.12),
                              child: const Icon(
                                Icons.person,
                                color: gRedMid,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['buyerName'] ?? "Buyer",
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (time != null)
                              Text(
                                "${time.day}/${time.month}/${time.year}",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (data['rating'] ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['reviewText'] ?? "",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Item: ${data['itemName'] ?? ''}",
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.9),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (!isMyPost &&
                  widget.sellerId != null &&
                  widget.sellerId!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerReviewsScreen(
                            sellerId: widget.sellerId!,
                            sellerName: sellerName,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gRedMid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text(
                      "View All Reviews",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE8EAF0);

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isMyPost = currentUid != null && currentUid == widget.sellerId;

    return Scaffold(
      backgroundColor: pageBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [gRedStart, gRedMid, gDarkEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Product Specifications",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 10, 30, 40),
                    child: Hero(
                      tag: widget.docId ?? "img",
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: (widget.itemImage != null &&
                                widget.itemImage!.length > 100)
                            ? Image.memory(
                                base64Decode(widget.itemImage!),
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 250,
                                color: Colors.white12,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white24,
                                  size: 60,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemName ?? "Campus Gear",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rs. ${widget.itemPrice ?? "0"}",
                    style: const TextStyle(
                      color: gRedStart,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMyPost
                          ? Colors.grey.withOpacity(0.08)
                          : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFFFF4F4)),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isMyPost
                                ? "Viewing your own listing"
                                : "Hi, is this still available?",
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isMyPost ? Colors.blueGrey : gRedMid,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isMyPost
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => NegotiationChat(
                                        docId: widget.docId,
                                        itemName: widget.itemName,
                                        itemImage: widget.itemImage,
                                        itemPrice: widget.itemPrice,
                                        sellerId: widget.sellerId,
                                        initialMessage:
                                            "Hello, is this still available?",
                                      ),
                                    ),
                                  ),
                          child: Text(
                            isMyPost ? "MY POST" : "CHAT",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAction(
                        isReported
                            ? Icons.report_gmailerrorred_rounded
                            : Icons.report_gmailerrorred_outlined,
                        "Report",
                        isReported,
                        _reportItemAction,
                        isDark,
                        cardBg,
                        borderColor,
                      ),
                      _buildAction(
                        Icons.favorite_rounded,
                        "Fav",
                        isFav,
                        () => _toggleCollection(
                          'user_favourites',
                          isFav,
                          (val) => isFav = val,
                        ),
                        isDark,
                        cardBg,
                        borderColor,
                      ),
                      _buildAction(
                        Icons.bookmark_added_rounded,
                        "Save",
                        isSaved,
                        () => _toggleCollection(
                          'user_saved',
                          isSaved,
                          (val) => isSaved = val,
                        ),
                        isDark,
                        cardBg,
                        borderColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Item Description",
                    style: TextStyle(
                      color: gRedStart,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.itemDescription ??
                        "Verified student gear available for campus trade inside the university safe network.",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 60, thickness: 0.8),
                  _buildSpecRow(
                    "Condition",
                    widget.itemCondition ?? "Clean Checked",
                    textSecondary,
                    textPrimary,
                  ),
                  _buildSpecRow(
                    "Seller Information",
                    sellerName,
                    textSecondary,
                    textPrimary,
                  ),
                  const SizedBox(height: 18),
                  if (!isMyPost) ...[
                    _buildSellerRatingPreview(
                      isDark,
                      cardBg,
                      borderColor,
                      textPrimary,
                      textSecondary,
                      isMyPost,
                    ),
                    const SizedBox(height: 18),
                  ],
                  _buildSpecRow(
                    "Item Trace ID",
                    widget.docId != null
                        ? "#${widget.docId!.substring(0, 5)}"
                        : "#99042",
                    textSecondary,
                    textPrimary,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    IconData i,
    String l,
    bool a,
    VoidCallback t,
    bool isDark,
    Color cb,
    Color bc,
  ) {
    return GestureDetector(
      onTap: t,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: a ? gRedStart.withOpacity(0.12) : cb,
              shape: BoxShape.circle,
              border: Border.all(color: a ? gRedStart : bc),
            ),
            child: Icon(i, color: a ? gRedStart : Colors.grey, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            l,
            style: TextStyle(
              color: a ? gRedStart : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String l, String r, Color s, Color p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(
              color: s,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              r,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}