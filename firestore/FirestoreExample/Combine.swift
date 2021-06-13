//
//  Copyright (c) 2020 Google LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Combine
import FirebaseFirestore

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
extension Query {
  /**
   * Reads the documents matching this query.
   *
   * This method returns a publisher that yields an array
   * of `QuerySnapshot`s, requiring the user to extract the underlying
   * `DocumentSnapshot`s before using them:
   *
   * ```
   * let noBooks = [Book]()
   * db.collection("books").getDocuments()
   *   .map { querySnapshot in
   *     querySnapshot.documents.compactMap { (queryDocumentSnapshot) in
   *       return try? queryDocumentSnapshot.data(as: Book.self)
   *     }
   *   }
   *   .replaceError(with: noBooks)
   *   .assign(to: \.books, on: self)
   *   .store(in: &cancellables)
   * ```
   */
  public func getDocuments() -> AnyPublisher<QuerySnapshot, Error> {
    Future<QuerySnapshot, Error> { [weak self] promise in
      self?.getDocuments { querySnapshot, error in
        if let error = error {
          promise(.failure(error))
        } else if let querySnapshot = querySnapshot {
          promise(.success(querySnapshot))
        } else {
          promise(.failure(NSError(domain: "FirebaseFirestoreSwift",
                                   code: -1,
                                   userInfo: [NSLocalizedDescriptionKey:
                                     "InternalError - Return type and Error code both nil in " +
                                     "getDocuments publisher"])))
        }
      }
    }
    .eraseToAnyPublisher()
  }
}

extension Query {

  public struct QuerySnapshotPublisher: Publisher {
    public typealias Output = QuerySnapshot
    public typealias Failure = Error

    private let query: Query

    init(_ query: Query) {
      self.query = query
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure,
      Self.Output == S.Input {
      let subscription = QuerySnaphotSubscription(subscriber: subscriber, query: query)
      subscriber.receive(subscription: subscription)
    }
  }

  fileprivate class QuerySnaphotSubscription<SubscriberType: Subscriber>: Subscription
    where SubscriberType.Input == QuerySnapshot, SubscriberType.Failure == Error {
    private var subscriber: SubscriberType?
    private var registration: ListenerRegistration?

    init(subscriber: SubscriberType, query: Query) {
      self.subscriber = subscriber

      registration = query.addSnapshotListener { querySnapshot, error in
        if let error = error {
          subscriber.receive(completion: .failure(error))
        } else if let querySnapshot = querySnapshot {
          _ = subscriber.receive(querySnapshot)
        }
      }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
      registration?.remove()
      registration = nil
      subscriber = nil
    }
  }

  public func snapshotPublisher() -> QuerySnapshotPublisher {
    return QuerySnapshotPublisher(self)
  }
}

// would like to be able to do this but it is currently illegal
// https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#parameterized-extensions
// extension Array where Element == Result<T, Error> {
//
// }

func sequence<T, E: Error>(_ arrayOfResults: [Result<T, E>]) -> Result<[T], E> {
  // haskell programmers naming variables be like
  // "wow. the code is so readable"
  return arrayOfResults.reduce(.success([])) { (p, q) in
    return p.flatMap { x in return q.map { y in return x + [y] } }
  }
}
