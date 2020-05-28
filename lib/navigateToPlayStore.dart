import 'package:store_redirect/store_redirect.dart';

goToPDFViewerFromPlayStore() {
  StoreRedirect.redirect(androidAppId: "com.google.android.apps.pdfviewer");
}

goToExcelViewerFromPlayStore() {
  StoreRedirect.redirect(
      androidAppId: "com.google.android.apps.docs.editors.sheets");
}
