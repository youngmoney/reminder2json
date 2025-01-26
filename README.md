# reminder2json

Get Apple Reminders in json format.

## Usage

Dump all reminders, with all (supported) fields:

```
reminder2json
```

Just get the fields needed for most tools, like [remind-md](http://github.com/youngmoney/remind-md):

```
reminder2json --output-format=remindmd
```


Control the lists:

```
reminder2json --include-lists=<regex> --exclude-lists=<regex>
```

Excluded lists are always excluded, even if they match an include.


## Help

If the output is empty, go to `Settings > Privacy & Security > Reminders` and ensure your terminal (or however you are running the command) has access.

## Releases

```
swift build --configuration release
cp .build/release/reminder2json bin/
```
