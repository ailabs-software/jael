
/** Interface represents an object (kind of injected dependency) providing ability to member resolution through reflection
 *  or other type of implementation */
abstract class IMemberResolver
{
  Object? getMember(Object? target, String name);
}

class DefaultMemberResolver implements IMemberResolver
{
  @override
  Object? getMember(Object? target, String name)
  {
    throw new UnsupportedError("Please configure reflection support in call to render.");
  }
}
