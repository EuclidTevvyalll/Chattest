import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

Future<void> listBuckets(SupabaseClient client) async {
  try {
    final buckets = await client.storage.listBuckets();
    for (var b in buckets) {
      debugPrint('Bucket: ${b.id}');
    }
  } catch (e) {
    debugPrint('Error listing buckets: $e');
  }
}


