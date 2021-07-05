---
layout: docs
toc_group: native-image
link_title: Using System Properties in Native Images
permalink: /reference-manual/native-image/Properties/
---
# Using System Properties in Native Images

Assume you have the following Java Program:
```java
public class App {
    public static void main(String[] args) {
        System.getProperties().list(System.out);
    }
}
```
If you compile that with, e.g., `native-image -Dfoo=bar App` the system property `foo` will be available at *image build time*.
For example, whenever you are in the [code that is part of your application but executed at image build time](http://www.graalvm.org/sdk/javadoc/org/graalvm/nativeimage/ImageInfo.html#inImageBuildtimeCode--) (usually static field initializations and static initializers).
Thus if you execute the image above it will not contain `foo` in the list of properties.

If, on the other hand, you execute the image with `app -Dfoo=bar`, it will show `foo` in the list of properties because you specified it for *image run time*.

In other words:
* Passing `-D<key>=<value>` to `native-image` affects properties seen at image build time.
* Passing `-D<key>=<value>` to an image execution affects properties seen at image run time.
