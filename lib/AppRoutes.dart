import 'package:pelican_dev/pages/BooksListScreen.dart';
import 'package:pelican_dev/pelican/PelicanRouter.dart';
import 'package:app_links/app_links.dart';

import 'models/Book.dart';
import 'pages/BookDetailsPage.dart';
import 'pages/SettingsPage.dart';
import 'pelican/PelicanRouteSegment.dart';

List<Book> books = [
  Book('1','Stranger in a Strange Land', 'Robert A. Heinlein'),
  Book('2','Foundation', 'Isaac Asimov'),
  Book('3','Fahrenheit 451', 'Ray Bradbury'),
];



class AppRoutes {

  static const BOOKS = 'books';
  static const SETTINGS = 'settings';
  static const ROOT = '/';

  static stringPar(String? par) {
    return par != null ? '='+par : '';
  }

  static String book({String? id, String? color, String? size}) => PelicanRouteSegment('book',{'id': id},{'color': color, 'size': size}).toPath();
  static String settings({String? vehicle_tab, String? section_tab}) => PelicanRouteSegment(SETTINGS,{'vehicle_tab': vehicle_tab, 'section_tab': section_tab}).toPath();

  static PelicanRouter? _router;
  static PelicanRouter get router => _router!;

  static init() async {
    var _appLinks = AppLinks();
    String? initialRoute;
    Uri? initialUri = await _appLinks.getInitialAppLink();
    print("initialUri ${initialUri.toString()}");
    if (initialUri!=null && initialUri.pathSegments.isNotEmpty) {
      initialRoute = initialUri.pathSegments.join('/');
      // initialRoute = 'books/settings;section_tab=Comfort;vehicle_tab=Car';
    } else {
      initialRoute = BOOKS;
    }

    // Handle link when app is in warm state (front or background)
    // _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
    //   print('onAppLink: $uri');
    //   openAppLink(uri);
    // });

     _router = PelicanRouter(
       initialRoute,
       RouteTable(
          {
            BOOKS: (routeContext) async {
              print('books');
              return routeContext.page(
                  BooksListScreen(
                      books: books,
                      onTapped: (bookModel) {
                        router.state.push(book(id: bookModel.id));
                      }
                  )
              );
            },
            book(): (routeContext) async {
              print('book');
              return routeContext.page(BookDetailsScreen(book: books.firstWhere((b) => b.id==routeContext.segment!.params['id'])));
            },
            SETTINGS: (routeContext) async {
              return routeContext.page(
                  SettingsPage(routeContext.segment!.params)
              );
            }
          },
          redirects: {
            ROOT: (_) async => BOOKS
          }
      ),
    );
  }

}
