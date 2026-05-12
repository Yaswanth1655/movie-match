import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get localId => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  TextColumn get movieTaste => text().withDefault(const Constant(''))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Catalogue rows keyed by OMDB IMDb id, e.g. `tt0816692`.
class Movies extends Table {
  TextColumn get tmdbId => text()();
  TextColumn get title => text()();
  TextColumn get overview => text().withDefault(const Constant(''))();
  TextColumn get posterPath => text().withDefault(const Constant(''))();
  TextColumn get releaseDate => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('omdb'))();
  IntColumn get sortIndex =>
      integer().withDefault(const Constant(1073741824))();
  TextColumn get rawPayload => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {tmdbId};
}

class SavedMovies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userLocalId =>
      integer().references(Users, #localId, onDelete: KeyAction.cascade)();
  TextColumn get tmdbId =>
      text().references(Movies, #tmdbId, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userLocalId, tmdbId},
      ];
}

@DriftDatabase(tables: [Users, Movies, SavedMovies])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(users, users.email);
          }
          if (from < 3) {
            await m.drop(savedMovies);
            await m.drop(movies);
            await m.createTable(movies);
            await m.createTable(savedMovies);
          }
          if (from >= 3 && from < 4) {
            await m.addColumn(movies, movies.sortIndex);
          }
        },
      );

  Future<int> upsertUser(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);

  Future<List<User>> getUsers({required int limit, required int offset}) {
    return (select(users)
          ..orderBy([(u) => OrderingTerm.desc(u.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Stream<List<User>> watchUsers() =>
      (select(users)..orderBy([(u) => OrderingTerm.desc(u.createdAt)])).watch();

  Future<List<User>> getPendingUsers() =>
      (select(users)..where((u) => u.pendingSync.equals(true))).get();

  Future<int> upsertMovie(MoviesCompanion movie) =>
      into(movies).insertOnConflictUpdate(movie);

  Future<void> upsertMovies(Iterable<MoviesCompanion> movieRows) {
    return transaction(() async {
      for (final movie in movieRows) {
        await into(movies).insertOnConflictUpdate(movie);
      }
    });
  }

  Future<List<Movy>> getMovies({required int limit, required int offset}) {
    return (select(movies)
          ..orderBy([(m) => OrderingTerm.asc(m.sortIndex)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<Movy?> getMovieByTmdbId(String tmdbId) =>
      (select(movies)..where((m) => m.tmdbId.equals(tmdbId))).getSingleOrNull();

  Future<void> toggleSavedMovie({
    required int userLocalId,
    required String tmdbId,
  }) async {
    final query = select(savedMovies)
      ..where(
          (s) => s.userLocalId.equals(userLocalId) & s.tmdbId.equals(tmdbId));
    final saved = await query.getSingleOrNull();
    if (saved == null) {
      await into(savedMovies).insert(
        SavedMoviesCompanion.insert(userLocalId: userLocalId, tmdbId: tmdbId),
      );
    } else {
      await (delete(savedMovies)..where((s) => s.id.equals(saved.id))).go();
    }
  }

  /// Total saves for this movie across all users.
  Stream<int> watchMovieSaveCount(String tmdbIdValue) {
    final countExp = savedMovies.id.count();
    final query = selectOnly(savedMovies)
      ..addColumns([countExp])
      ..where(savedMovies.tmdbId.equals(tmdbIdValue));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Stream<bool> watchIsMovieSavedForUser({
    required int userLocalId,
    required String tmdbId,
  }) {
    final q = select(savedMovies)
      ..where(
          (s) => s.userLocalId.equals(userLocalId) & s.tmdbId.equals(tmdbId));
    return q.watch().map((rows) => rows.isNotEmpty);
  }

  Stream<List<User>> watchUsersForMovie(String tmdbIdValue) {
    final joinQuery = select(users).join([
      innerJoin(savedMovies, savedMovies.userLocalId.equalsExp(users.localId)),
    ])
      ..where(savedMovies.tmdbId.equals(tmdbIdValue));

    return joinQuery.watch().map((rows) {
      return rows.map((row) => row.readTable(users)).toList();
    });
  }

  Future<int> _countAllUsers() async {
    final countExp = users.localId.count();
    final q = selectOnly(users)..addColumns([countExp]);
    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Matches: movies saved by 2+ distinct users; live stream; ordered by save count desc.
  Stream<List<MovieWithCount>> watchMatches() {
    final distinctSavers = savedMovies.userLocalId.count(distinct: true);
    final query = select(movies).join([
      innerJoin(savedMovies, savedMovies.tmdbId.equalsExp(movies.tmdbId)),
    ])
      ..addColumns([distinctSavers])
      ..groupBy([movies.tmdbId])
      ..orderBy([OrderingTerm.desc(distinctSavers)]);

    return query.watch().asyncMap((rows) async {
      final totalUsers = await _countAllUsers();
      return rows
          .map((row) {
            final saveCount = row.read(distinctSavers) ?? 0;
            return MovieWithCount(
              movie: row.readTable(movies),
              saveCount: saveCount,
              isTopPick: totalUsers > 0 && saveCount >= totalUsers,
            );
          })
          .where((item) => item.saveCount >= 2)
          .toList();
    });
  }

  Stream<List<Movy>> watchSavedMoviesForUser(int userId) {
    final joinQuery = select(movies).join([
      innerJoin(savedMovies, savedMovies.tmdbId.equalsExp(movies.tmdbId)),
    ])
      ..where(savedMovies.userLocalId.equals(userId))
      ..orderBy([OrderingTerm.desc(savedMovies.createdAt)]);

    return joinQuery.watch().map((rows) {
      return rows.map((row) => row.readTable(movies)).toList();
    });
  }
}

class MovieWithCount {
  const MovieWithCount({
    required this.movie,
    required this.saveCount,
    required this.isTopPick,
  });

  final Movy movie;
  final int saveCount;
  final bool isTopPick;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'movie_match.sqlite'));
    return NativeDatabase(file);
  });
}
