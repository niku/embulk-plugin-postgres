# Embulk output plugin for PostgreSQL

This [Embulk](https://github.com/embulk/embulk) output plugin writes records to columns of a table.

## Configuration

- **host** host name of the PostgreSQL server (string, required)
- **port** port of the PostgreSQL server (integer, default: 5432)
- **username** login user name (string, required)
- **password** login password (string, default: "")
- **database** destination database name (string, required)
- **table** destination table name (string, required)

### Example

```yaml
out:
  type: postgres
  host: localhost
  username: niku
  database: embulk_test
  table: load01
```

## How to execute example

### prepare db and table

```shell
$ createdb -Eutf8 embulk_test
$ psql -d embulk_test -c 'CREATE TABLE load01(id integer, account integer, time timestamp, purchase timestamp, comment varchar);'
```

### prepare embulk

```
$ curl https://bintray.com/artifact/download/embulk/maven/embulk-0.3.2.jar -L -o embulk.jar
$ java -jar embulk.jar bundle ./embulk_bundle
$ echo 'gem "embulk-plugin-postgres", github: "niku/embulk-plugin-postgres"' >> ./embulk_bundle/Gemfile
$ java -jar embulk.jar bundle ./embulk_bundle
$ java -jar embulk.jar -b ./embulk_bundle example ./try1
$ java -jar embulk.jar -b ./embulk_bundle guess ./try1/example.yml -o config.yml
```

### rewrite config.yaml

```yaml
in:
  type: file
  paths: [/Users/niku/try1/csv]
  decoders:
  - {type: gzip}
  parser:
    charset: UTF-8
    newline: CRLF
    type: csv
    delimiter: ','
    quote: '"'
    header_line: true
    columns:
    - {name: id, type: long}
    - {name: account, type: long}
    - {name: time, type: timestamp, format: '%Y-%m-%d %H:%M:%S'}
    - {name: purchase, type: timestamp, format: '%Y%m%d'}
    - {name: comment, type: string}
exec: {}
out:
  type: postgres
  host: localhost
  username: niku
  database: embulk_test
  table: load01
```

### execute embulk

```
$ java -jar embulk.jar -b ./embulk_bundle run config.yml
```

### check db

```
$ psql -d embulk_test -c 'SELECT * FROM load01;'
 id | account |        time         |      purchase       |          comment
----+---------+---------------------+---------------------+----------------------------
  1 |   32864 | 2015-01-27 19:23:49 | 2015-01-27 00:00:00 | embulk
  2 |   14824 | 2015-01-27 19:01:23 | 2015-01-27 00:00:00 | embulk jruby
  3 |   27559 | 2015-01-28 02:20:02 | 2015-01-28 00:00:00 | embulk core
  4 |   11270 | 2015-01-29 11:54:36 | 2015-01-29 00:00:00 | Embulk "csv" parser plugin
  (4 rows)
```

Yay!
